library("stars")

variables = list.files("data/variables", pattern = ".tif", full.names = TRUE)
n = length(variables)
df = data.frame(min = double(n), max = double(n), mean = double(n), sd = double(n))

for (i in seq_along(variables)) {
  cat(i, "/", n, "\n")
  r = read_stars(variables[i], proxy = FALSE)
  df[i, "min"] = min(r[[1]], na.rm = TRUE)
  df[i, "max"] = max(r[[1]], na.rm = TRUE)
  df[i, "mean"] = mean(r[[1]], na.rm = TRUE)
  df[i, "sd"] = sd(r[[1]], na.rm = TRUE)
}

df = round(df, 2)

name = basename(variables)
name = substr(name, 1, nchar(name) - 4)
name = substr(name, 4, nchar(name))
df = cbind(name, df)

df
#         name    min       max     mean       sd
# 1  ELEVATION  -0.03   2483.00   170.92   129.18
# 2      SLOPE   0.00     76.07     1.75     3.08
# 3      STDEV   0.00    262.66     5.05     8.30
# 4   MULTITPI -53.13     44.61     0.00     0.70
# 5  CONVEXITY   0.00     88.61    48.68     7.55
# 6    ENTROPY   6.78 940317.88 52440.92 44507.88
# 7   OPENNESS   0.61      1.70     1.55     0.03
# 8  MEDIAN500   0.00   2335.16   170.69   128.95
# 9 MEDIAN1000   0.00   2238.39   170.49   128.49
