library("ranger")
library("yardstick")
set.seed(1)

df = readRDS("data/dataset.rds")
n = round(0.7 * nrow(df))
trainIndex = sample(nrow(df), size = n)
train = df[trainIndex, ]
test = df[-trainIndex, ]
rm(df, trainIndex)
num_class = length(unique(train$class))

## tuning parameters
num.trees = c(100, 500, 1000)
mtry = c(2, 3, 4, 5)
min.node.size = c(1, 5, 10)
max.depth = c(5, 10, 15, 20)

param_names = c("num.trees", "mtry", "min.node.size", "max.depth")
param_df = expand.grid(num.trees, mtry, min.node.size, max.depth,
                       KEEP.OUT.ATTRS = FALSE)
colnames(param_df) = param_names

## random search
idx = sample(nrow(param_df), nrow(param_df) / 2) # 72 models

acc = rep(NA_real_, times = nrow(param_df))
ii = 1 # loop counter
for (i in idx) {

  cat(ii, "/", length(idx), "\n")

  model = ranger(class ~ ., train, importance = "impurity",
                 num.trees = param_df$num.trees[i],
                 mtry = param_df$mtry[i],
                 min.node.size = param_df$min.node.size[i],
                 max.depth = param_df$max.depth[i],
                 seed = 1, verbose = FALSE,
                 num.threads = 12)
  model$predictions = NULL # remove predictions from model

  ## predict
  pred = predict(model, test[, -1], verbose = FALSE)$predictions

  ## make sure model can predict all classes
  if (length(levels(pred)) != num_class) {
    acc[i] = -1
  } else {
    acc[i] = accuracy_vec(test$class, pred)
  }

  ii = ii + 1

}

param_df = cbind(param_df, accuracy = acc)
idx_max = which.max(param_df$accuracy)
param_df[idx_max, ]

if (!dir.exists("results")) dir.create("results")
write.csv(param_df, "results/randomforest.csv", row.names = FALSE)
