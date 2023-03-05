spatial_predict = function(model, df, class_ID) {
  ## predict() in XGBoost runs in parallel by default (uses all threads)
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
