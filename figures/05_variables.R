library("stars")
library("ggplot2")
library("cowplot")

variables = list.files("data/variables", pattern = ".tif", full.names = TRUE)

names = c("slope", "stdev", "multitpi", "convexity", "entropy", "openness")
var = read_stars(variables[-c(1, 8, 9)], proxy = TRUE)
var = st_downsample(var, 15) # downsample to 480 m
var = as.data.frame(var)
colnames(var)[3:8] = names

p1 = ggplot() +
  geom_raster(data = var, aes(x = x, y = y, fill = slope)) +
  scale_fill_distiller(palette = "Greys", na.value = NA, name = NULL) +
  labs(title = "Slope") +
  coord_equal() +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
p1

p2 = ggplot() +
  geom_raster(data = var, aes(x = x, y = y, fill = stdev)) +
  scale_fill_distiller(palette = "Greys", na.value = NA, name = NULL) +
  labs(title = "St. Dev.") +
  coord_equal() +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
p2

# sinus transformation
p3 = ggplot() +
  geom_raster(data = var, aes(x = x, y = y, fill = sin(multitpi))) +
  scale_fill_distiller(palette = "Greys", na.value = NA, name = NULL) +
  labs(title = "Multi-scale TPI") +
  coord_equal() +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
p3

p4 = ggplot() +
  geom_raster(data = var, aes(x = x, y = y, fill = convexity)) +
  scale_fill_distiller(palette = "Greys", na.value = NA, name = NULL) +
  labs(title = "Convexity") +
  coord_equal() +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
p4

p5 = ggplot() +
  geom_raster(data = var, aes(x = x, y = y, fill = entropy / 1000)) +
  scale_fill_distiller(palette = "Greys", na.value = NA, name = NULL) +
  labs(title = "Entropy") +
  coord_equal() +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
p5

p6 = ggplot() +
  geom_raster(data = var, aes(x = x, y = y, fill = openness)) +
  scale_fill_distiller(palette = "Greys", na.value = NA, name = NULL) +
  labs(title = "Openness") +
  coord_equal() +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
p6

var = read_stars(variables[8], proxy = TRUE)
var = st_downsample(var, 110) # downsample to 3300 m
var = as.data.frame(var)
colnames(var)[3] = "median500"

fact = 2400 / max(var$median500, na.rm = TRUE) # fix maximum value
p7 = ggplot() +
  geom_raster(data = var, aes(x = x, y = y, fill = median500 * fact )) +
  scale_fill_distiller(palette = "Greys", na.value = NA, name = NULL) +
  labs(title = "Median (500 m)") +
  coord_equal() +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
p7

var = read_stars(variables[9], proxy = TRUE)
var = st_downsample(var, 190) # downsample to 5700 m
var = as.data.frame(var)
colnames(var)[3] = "median1000"

fact = 2400 / max(var$median1000, na.rm = TRUE) # fix maximum value
p8 = ggplot() +
  geom_raster(data = var, aes(x = x, y = y, fill = median1000 * fact)) +
  scale_fill_distiller(palette = "Greys", na.value = NA, name = NULL) +
  labs(title = "Median (1000 m)") +
  coord_equal() +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
p8
