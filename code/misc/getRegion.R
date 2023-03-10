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
