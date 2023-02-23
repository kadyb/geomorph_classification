library("lightgbm")
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
test$class = factor(as.numeric(test$class))

## tuning parameters
learning_rate = c(0.1, 0.05, 0.01)
max_bin = c(256, 512, 1024, 2048)
num_leaves = c(40, 50, 60, 70)
nrounds = c(100, 150)
boosting = c("gbdt", "dart")
max_depth = c(10, 15, 20)
bagging_fraction = c(1, 0.8, 0.6)
feature_fraction = c(1, 0.7, 0.5)

param_names = c("learning_rate", "max_bin", "num_leaves", "nrounds",
                "boosting", "max_depth", "bagging_fraction", "feature_fraction")
param_df = expand.grid(learning_rate, max_bin, num_leaves, nrounds,
                       boosting, max_depth, bagging_fraction, feature_fraction,
                       KEEP.OUT.ATTRS = FALSE)
colnames(param_df) = param_names

## random search
idx = sample(nrow(param_df), nrow(param_df) / 5) # 1036 models

acc = rep(NA_real_, times = nrow(param_df))
ii = 1 # loop counter
for (i in idx) {

  cat(ii, "/", length(idx), "\n")

  params = list(
    objective = "multiclass",
    learning_rate = param_df$learning_rate[i],
    max_bin = param_df$max_bin[i],
    num_leaves = param_df$num_leaves[i],
    boosting = param_df$boosting[i],
    max_depth = param_df$max_depth[i],
    bagging_fraction = param_df$bagging_fraction[i],
    is_unbalance = TRUE,
    num_class = length(unique(train$class)),
    seed = 1,
    deterministic = TRUE,
    num_threads = 12
  )

  ## dataset must be recreated after every iteration due to "max_bin"
  lgb_train = lgb.Dataset(as.matrix(train[, -1]), label = train$class)
  model = lgb.train(params = params, data = lgb_train, verbose = -1,
                    nrounds = param_df$nrounds[i])

  ## predict
  pred = predict(model, as.matrix(test[, -1]), reshape = TRUE)
  pred_class = max.col(pred)
  pred_class = factor(pred_class)

  ## make sure model can predict all classes
  if (length(levels(pred_class)) != 52) {
    acc[i] = -1
  } else {
    acc[i] = accuracy_vec(test$class, pred_class)
  }

  ii = ii + 1

}

param_df = cbind(param_df, accuracy = acc)
if (!dir.exists("results")) dir.create("results")
write.csv(param_df, "results/lightgbm.csv", row.names = FALSE)
