library("stars")
library("xgboost")
library("ALEPlot")
set.seed(1)


outdir = file.path("data", "rds")
if (!dir.exists(outdir)) dir.create(outdir)

names = c("elevation", "slope", "stdev", "multitpi", "convexity",
          "entropy", "openness", "median500", "median1000")
reference = list.files("data/raster_maps", pattern = ".tif", full.names = TRUE)
variables = list.files("data/variables", pattern = ".tif", full.names = TRUE)
var = read_stars(variables, proxy = TRUE)

ref = reference[1] # choose sheet manually
ref = read_stars(ref)
ref[[1]] = as.integer(ref[[1]])

var_crop = st_crop(var, st_bbox(ref))
var_crop = st_as_stars(var_crop) # load into memory
df = as.data.frame(var_crop)[, -c(1:2)]
df = na.omit(df)
df = df[sample(nrow(df), 300000), ]
colnames(df) = names

mdl = xgb.load("results/xgb.model")

classes = unique(as.vector(ref[[1]]))
classes[classes == 50 | classes == 21] = NA
classes = classes[!is.na(classes)]
classes = sort(classes)

## need to swap the numbering from xgboost to classification table
tab = read.csv("data/classification_table.csv")
tab = tab[tab$CODE != 0, ]
tab = tab[tab$CODE != 21, ]
tab = tab[tab$CODE != 50, ]
tab$xgb_class = as.integer(as.factor(tab$CODE)) - 1L # range: 0 - 51

## match table
xgb_classes = tab$xgb_class[tab$CODE %in% classes]


ALE_df = data.frame(x = double(), y = double(), var = integer(), class = integer())
for (class in xgb_classes) {

  yhat = function(X.model, newdata) {
    p = predict(X.model, as.matrix(newdata), reshape = TRUE)
    class = class + 1 # start numbering from 1 not 0
    p = p[, class]
  }

  ## iterate over variables
  for (j in 1:7) {
    ALE = ALEPlot(df, mdl, pred.fun = yhat, J = j)
    ALE_df = rbind(ALE_df,
                   cbind(x = ALE$x.values, y = ALE$f.values, var = j, class = class))
  }

}

names = c("Elevation", "Slope", "St. Dev.", "Multi-scale TPI", "Convexity",
          "Entropy", "Openness")
ALE_df$var = factor(ALE_df$var, labels = names)
ALE_df$class2 = factor(ALE_df$class, labels = tab$EN[match(classes, tab$CODE)])
ALE_df$x[ALE_df$var == "Entropy"] = ALE_df$x[ALE_df$var == "Entropy"] / 1000

## save results
saveRDS(ALE_df, file = file.path(outdir, "Jelenia_Gora.rds")) # change name manually
