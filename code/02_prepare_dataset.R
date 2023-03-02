library("stars")
library("corrr")

tab = read.csv("data/classification_table.csv")
files = list.files("data/digital_maps", recursive = TRUE,
                   pattern = "OK_POWIERZCHNIE_PODSTAWOWE+\\.shp$",
                   full.names = TRUE)

## this function returns the name of the sheet from the filepath
getRegion = function(f) {
  x = unlist(strsplit(f, split = "/", fixed = TRUE))
  x = x[3]
  x = unlist(strsplit(x, "_", fixed = TRUE))
  x = x[-c(1:5)]
  x = x[1:(length(x) - 1)] # remove last segment
  x = paste(x, collapse = "_")
  return(x)
}

res = c(30, 30)
if (!dir.exists("data/raster_maps")) dir.create("data/raster_maps")

## rasterize geomorphological maps
for (f in files) {

  vec = read_sf(f)
  vec = st_transform(vec, crs = 2180)
  vec = merge(vec, tab[, c(1, 4)], by = "ID_FORM")
  name = getRegion(f)
  template = st_as_stars(st_bbox(vec), dx = res[1], dy = res[2], values = 0L)
  ras = st_rasterize(vec["CODE"], template, proxy = TRUE)
  filepath = paste0("data/raster_maps/", name, ".tif")
  write_stars(ras, filepath, type = "Byte", NA_value = 0)

}


## create data frame from rasters
files = list.files("data/raster_maps", pattern = ".tif", full.names = TRUE)
variables = list.files("data/variables", pattern = ".tif", full.names = TRUE)
var = read_stars(variables, proxy = TRUE)

class_vec = integer()
names = c("elevation", "slope", "stdev", "multitpi", "convexity",
           "entropy", "openness", "median500", "median1000")
var_df = data.frame()

for (f in files) {

  class = read_stars(f, proxy = FALSE)
  class[[1]] = as.integer(class[[1]])
  var_crop = st_crop(var, st_bbox(class))
  var_crop = st_as_stars(var_crop) # load into memory
  var_crop = st_warp(var_crop, class, method = "near") # align grids
  class = as.vector(class[[1]])
  var_crop = data.frame(var_crop)[, -c(1, 2)]
  colnames(var_crop) = names

  class_vec = c(class_vec, class)
  var_df = rbind(var_df, var_crop)

}

rm(var_crop, class)
df = cbind(class = factor(class_vec), var_df) # ID class as factor
df = df[which(complete.cases(df)), ] # remove NAs
rm(var_df, class_vec)

## deal with class inbalance
tab = sort(table(df$class))
tab

## reduce largest classes to 150k observations
size = 150000
cols_idx = names(which(tab > size))

for (i in cols_idx) {
  val = tab[[i]] - size
  idx = sample(which(df$class == i), val)
  df[idx, ] = NA
}
rm(idx)

## remove smallest classes: 50, 21
df[which(df$class == 50), ] = NA
df[which(df$class == 21), ] = NA
df = df[which(complete.cases(df)), ]
df$class = droplevels(df$class)

## check linear correlation of variables
cor = correlate(df[, -1])
rplot(cor, print_cor = TRUE)

rownames(df) = NULL
saveRDS(df, "data/dataset.rds")
