spatial_predict = function(model, df, class_ID) {
  ## predict() in XGBoost uses as many threads as set in `xgb.Booster` (all by default)
  ## additionally, conversion matrix to `xgb.DMatrix` uses multiple threads too
  pred = predict(model, as.matrix(df), reshape = TRUE)
  pred_class = max.col(pred) - 1L
  prob_class = pred[, class_ID] * 100
  uncertainty = numeric(nrow(pred))
  for (i in seq_along(uncertainty)) {
    uncertainty[i] = 1 - max(pred[i, ])
  }
  uncertainty = uncertainty * 100
  output = data.frame(pred_class, prob_class, uncertainty)
  names(output) = c("class", "probability", "uncertainty")
  ## probability and uncertainty are returned as percentages
  return(output)
}
