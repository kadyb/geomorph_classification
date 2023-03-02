library("xgboost")
library("yardstick")
set.seed(1)

df = readRDS("data/dataset.rds")
n = round(0.7 * nrow(df))
trainIndex = sample(nrow(df), size = n)
train = df[trainIndex, ]
test = df[-trainIndex, ]
rm(df, trainIndex)

# class must be numeric, start with 0 and numbering must be continuous
train$class = as.numeric(train$class) - 1
num_class = length(unique(train$class))
xgb_train = xgb.DMatrix(as.matrix(train[, -1]), label = train$class)
test$class = factor(as.numeric(test$class))

## tuning parameters
eta = c(0.3, 0.2, 0.1, 0.05)
max_depth = c(5, 10, 15, 20)
nrounds = c(50, 100, 150)
subsample = c(1, 0.8, 0.6)

param_names = c("eta", "max_depth", "nrounds", "subsample")
param_df = expand.grid(eta, max_depth, nrounds, subsample,
                       KEEP.OUT.ATTRS = FALSE)
colnames(param_df) = param_names

## random search
idx = sample(nrow(param_df), nrow(param_df) / 2) # 72 models

acc = rep(NA_real_, times = nrow(param_df))
ii = 1 # loop counter
for (i in idx) {

  cat(ii, "/", length(idx), "\n")

  params = list(
    objective = "multi:softprob",
    eta = param_df$eta[i],
    max_depth = param_df$max_depth[i],
    subsample = param_df$subsample[i],
    nthread = 12
  )

  model = xgb.train(xgb_train, nrounds = param_df$nrounds[i], params = params,
                    num_class = num_class)

  ## predict
  pred = predict(model, as.matrix(test[, -1]), reshape = TRUE)
  pred_class = max.col(pred)
  pred_class = factor(pred_class)

  ## make sure model can predict all classes
  if (length(levels(pred_class)) != num_class) {
    acc[i] = -1
  } else {
    acc[i] = accuracy_vec(test$class, pred_class)
  }

  ii = ii + 1

}

param_df = cbind(param_df, accuracy = acc)
idx_max = which.max(param_df$accuracy)
param_df[idx_max, ]

if (!dir.exists("results")) dir.create("results")
write.csv(param_df, "results/xgboost.csv", row.names = FALSE)
