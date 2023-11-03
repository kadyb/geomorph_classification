library("stars")
library("xgboost")
set.seed(1)

## MODEL TRAINING --------------------------------------------------------------
## train model on whole dataset
df = readRDS("data/dataset.rds")
df$class = as.numeric(df$class) - 1
num_class = length(unique(df$class))
xgb_train = xgb.DMatrix(as.matrix(df[, -1]), label = df$class)

params = list(
  objective = "multi:softprob",
  # nrounds = 150,
  eta = 0.2,
  max_depth = 20,
  subsample = 0.6,
  nthread = 12
)

model = xgb.train(xgb_train, nrounds = 150, params = params, num_class = num_class)
xgb.save(model, "results/xgb.model")

## variable importance
var_imp = xgb.importance(model = model)
write.csv(var_imp, "results/variable_importance.csv", row.names = FALSE)

## PREDICT ---------------------------------------------------------------------
rm(list = ls())
source("code/misc/spatial_predict.R")

## example class to determine the probability of occurrence
## 14: rock wall or rock slope
class_ID = 14 - 2

variables = list.files("data/variables/", pattern = ".tif", full.names = TRUE)
var = read_stars(variables, proxy = TRUE)
model = xgb.load("results/xgb.model")
names = c("elevation", "slope", "stdev", "multitpi", "convexity",
          "entropy", "openness", "median500", "median1000")

blocks = st_tile(nrow(var), ncol(var), 1028, 1028)
dir = file.path("output", "tiles")
if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)

for (i in seq_len(nrow(blocks))) {

  cat(i, "/", nrow(blocks), "\n")

  block = read_stars(var, proxy = FALSE, RasterIO = blocks[i, ])
  df = data.frame(block)
  crds = df[, 1:2]
  df = df[, -c(1, 2)]
  colnames(df) = names
  NA_found = anyNA(df)

  if (NA_found) {
    if (all(is.na(df))) next # skip if all pixels are NA
    idx = which(complete.cases(df))
    pred = spatial_predict(model, df[idx, ], class_ID = class_ID)
    crds = cbind(crds, class = NA, probability = NA, uncertainty = NA)
    crds[idx, 3:5] = pred
  } else {
    pred = spatial_predict(model, df, class_ID = class_ID)
    crds = cbind(crds, pred)
  }

  output = st_as_stars(crds)
  st_crs(output) = 2180

  ## save class
  save_path = file.path(dir, paste0("class", i, ".tif"))
  write_stars(output["class"], save_path, options = "COMPRESS=LZW",
              type = "Byte", NA_value = 255, chunk_size = dim(block))
  ## save probability
  save_path = file.path(dir, paste0("probability", i, ".tif"))
  write_stars(output["probability"], save_path, options = "COMPRESS=LZW",
              type = "Float32", NA_value = 999, chunk_size = dim(block))
  ## save uncertainty
  save_path = file.path(dir, paste0("uncertainty", i, ".tif"))
  write_stars(output["uncertainty"], save_path, options = "COMPRESS=LZW",
              type = "Float32", NA_value = 999, chunk_size = dim(block))

}


## merge tiles for classes
tiles_path = list.files(dir, pattern = "class+.+\\.tif$", full.names = TRUE)
tmp = tempfile(fileext = ".vrt")
gdal_utils(util = "buildvrt", source = tiles_path, destination = tmp)
gdal_utils(util = "translate", source = tmp, destination = file.path("output", "classification.tif"),
           options = c("-co", "COMPRESS=LZW"))

## merge tiles for probability
tiles_path = list.files(dir, pattern = "probability+.+\\.tif$", full.names = TRUE)
tmp = tempfile(fileext = ".vrt")
gdal_utils(util = "buildvrt", source = tiles_path, destination = tmp)
gdal_utils(util = "translate", source = tmp, destination = file.path("output", "probability.tif"),
           options = c("-co", "COMPRESS=LZW"))

## merge tiles for uncertainty
tiles_path = list.files(dir, pattern = "uncertainty+.+\\.tif$", full.names = TRUE)
tmp = tempfile(fileext = ".vrt")
gdal_utils(util = "buildvrt", source = tiles_path, destination = tmp)
gdal_utils(util = "translate", source = tmp, destination = file.path("output", "uncertainty.tif"),
           options = c("-co", "COMPRESS=LZW"))

## POSTPROCESSING --------------------------------------------------------------
rm(list = ls())

## need to swap the numbering from xgboost to classification table
tab = read.csv("data/classification_table.csv")
tab = tab[tab$CODE != 0, ]
tab = tab[tab$CODE != 21, ]
tab = tab[tab$CODE != 50, ]
old_class = as.integer(as.factor(tab$CODE)) - 1L # range: 0 - 51

r = read_stars("output/classification.tif", proxy = FALSE)
r[[1]] = as.integer(r[[1]])

## reclassify
## need to add one more break in `cut()`
r[[1]] = cut(r[[1]], breaks = c(-1L, old_class), labels = tab$CODE)
r[[1]] = as.integer(as.character(r[[1]])) # factor to numeric

## overwrite
write_stars(r, file.path("output", "classification.tif"), options = "COMPRESS=LZW",
            type = "Byte", NA_value = 255)

## remove small patches
system(
  paste(
    "gdal_sieve.py", "-st 20", "output/classification.tif", "output/classification_post.tif"
  )
)

## smooth raster
tmp = tempfile(fileext = ".sdat")
system(
  paste(
    "saga_cmd grid_filter 6",
    "-INPUT", "output/classification_post.tif",
    "-RESULT", tmp,
    "-KERNEL_RADIUS", 2
  )
)

## compress and change datatype
system(
  paste(
    "gdal_translate", tmp, "output/classification_post.tif",
    "-co COMPRESS=LZW", "-ot Byte"
  )
)
