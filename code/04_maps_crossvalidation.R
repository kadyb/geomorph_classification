library("stars")
library("xgboost")
library("yardstick")
set.seed(1)
folds = 5


files = list.files("data/raster_maps/", pattern = ".tif", full.names = TRUE)
variables = list.files("data/variables", pattern = ".tif", full.names = TRUE)
var = read_stars(variables, proxy = TRUE)
names = c("elevation", "slope", "stdev", "multitpi", "convexity",
          "entropy", "openness", "median500", "median1000")

acc_result = double()
kap_result = double()
mcc_result = double()

## best hyperparameters from previous tuning
params = list(
  objective = "multi:softprob",
  # nrounds = 150,
  eta = 0.2,
  max_depth = 20,
  subsample = 0.6,
  nthread = 12
)

## loop over the maps
for (f in files) {

  cat("Sheet:", basename(f), "\n")
  class = read_stars(f, proxy = FALSE)
  class[[1]] = as.integer(class[[1]])
  var_crop = st_crop(var, st_bbox(class))
  var_crop = st_as_stars(var_crop) # load into memory
  var_crop = st_warp(var_crop, class, method = "near") # align grids

  df = data.frame(var_crop)[, -c(1, 2)]
  colnames(df) = names
  class = as.vector(class[[1]])
  df = cbind(class, df)
  rm(var_crop, class)
  df = df[which(complete.cases(df)), ]

  ## balance classes (if the number of occurrences
  ## is above the threshold, remove the excess ones)
  tab = table(df$class)
  size = quantile(as.vector(tab), 0.6, names = FALSE)
  cols_idx = names(which(tab > size))
  for (i in cols_idx) {
    val = tab[[i]] - size
    idx = sample(which(df$class == i), val)
    df[idx, ] = NA
  }
  df = df[which(complete.cases(df)), ]
  df$class = as.numeric(factor(df$class)) - 1 # prepare class numbering

  ## crossvalidation
  idx = sample(nrow(df))
  size = length(idx) / folds
  folds_id = split(idx, ceiling(seq_along(idx) / size))

  i = 1
  for (k in seq_along(folds_id)) {

    cat("Fold", i, "/", folds, "\n")

    train_idx = unlist(folds_id[-k])
    train = df[train_idx, ]
    num_class = length(unique(train$class))
    train = xgb.DMatrix(as.matrix(train[, -1]), label = train$class)
    test = df[folds_id[[k]], ]
    test$class = factor(test$class)

    model = xgb.train(train, nrounds = 150, params = params, num_class = num_class)

    pred = predict(model, as.matrix(test[, -1]), reshape = TRUE)
    pred_class = max.col(pred) - 1L
    pred_class = factor(pred_class)

    if (length(unique(pred_class)) != num_class) {
      acc_result = c(acc_result, NA)
      kap_result = c(kap_result, NA)
      mcc_result = c(mcc_result, NA)
    } else {
      acc_result = c(acc_result, accuracy_vec(test$class, pred_class))
      kap_result = c(kap_result, kap_vec(test$class, pred_class))
      mcc_result = c(mcc_result, mcc_vec(test$class, pred_class))
    }

    i = i + 1

  }

}


sheet = c("Jelenia Góra", "Katowice", "Kraków Zachodni", "Kutno",
          "Nowy Targ", "Świnoujście", "Tomaszów Lubelski", "Toruń")
sheet = rep(sheet, each = folds)
result = data.frame(acc = acc_result, kappa = kap_result, mcc = mcc_result)
result = aggregate(result, by = list(sheet = sheet), FUN = "mean", na.rm = TRUE)

write.csv(result, "results/maps_crossvalidation.csv", row.names = FALSE)
