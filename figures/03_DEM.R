library("stars")
library("ggplot2")
library("cowplot")
library("ggnewscale")

dem = read_stars("data/variables/01_ELEVATION.tif", proxy = TRUE)
dem = st_downsample(dem, 15) # downsample to 480 m
dem[[1]] = as.integer(dem[[1]])
names(dem) = "dem"

tmp = tempfile(fileext = ".sdat")
system(
  paste(
    "saga_cmd ta_lighting 0",
    "-ELEVATION", "data/variables/01_ELEVATION.tif",
    "-SHADE", tmp
  )
)
hillshade = read_stars(tmp, proxy = TRUE)
hillshade = st_downsample(hillshade, 15) # downsample to 480 m
hillshade[[1]] = as.integer(hillshade[[1]])
names(hillshade) = "hillshade"

vertical = colMeans(dem[[1]], na.rm = TRUE)
vertical[is.na(vertical)] = 0
horizontal = rowMeans(dem[[1]], na.rm = TRUE)
horizontal[is.na(horizontal)] = 0

dem = as.data.frame(dem)
hillshade = as.data.frame(hillshade)

topo = read.csv("figures/03_topo_colors.csv", header = FALSE)
topo$hex = rgb(topo / 255)

# more visable hillshade
q_hill = quantile(hillshade$hillshade, c(0.01, 0.99), na.rm = TRUE)
hillshade$hillshade[hillshade$hillshade < q_hill[1]] = q_hill[1]
hillshade$hillshade[hillshade$hillshade > q_hill[2]] = q_hill[2]

p1 = ggplot() +
  geom_raster(data = hillshade, aes(x = x, y = y, fill = hillshade),
              show.legend = FALSE) +
  scale_fill_distiller(palette = "Greys", na.value = NA) +
  new_scale_fill() +
  geom_raster(data = dem, aes(x = x, y = y,  fill = sqrt(dem)), alpha = 0.7) +
  scale_fill_gradientn(colors = topo$hex, na.value = NA,
                       labels = c(0, 500, 1000, 1500, 2000, 2500),
                       name = NULL) +
  guides(fill = guide_colourbar(barwidth = 10)) +
  coord_equal() +
  theme_void() +
  theme(legend.position = "bottom")
p1

## side histograms
vertical = data.frame(x = seq_along(vertical), y = vertical)
horizontal = data.frame(x = seq_along(horizontal), y = horizontal)

p2 = ggplot(vertical, aes(-x, y, fill = y)) +
  geom_col(width = 1, show.legend = FALSE) +
  geom_hline(yintercept = c(250, 500), linetype = "dashed") +
  annotate("text", x = -150, y = 590, angle = 270, label = "500 m asl") +
  annotate("text", x = -150, y = 340, angle = 270, label = "250 m asl") +
  coord_flip() +
  scale_fill_gradientn(colors = topo$hex) +
  theme_void()
p2

v_max = max(vertical$y, na.rm = TRUE)
h_max = max(horizontal$y, na.rm = TRUE)
idx = as.integer(nrow(topo) * h_max / v_max) # cut color scale

p3 = ggplot(horizontal, aes(x, y, fill = y)) +
  geom_col(width = 1, show.legend = FALSE) +
  geom_hline(yintercept = 125, linetype = "dashed") +
  annotate("text", x = 80, y = 230, label = "125 m asl") +
  scale_fill_gradientn(colors = topo$hex[seq_len(idx)]) +
  ylim(0, 1000) +
  theme_void()
p3

## final plot
plot_final = insert_xaxis_grob(p1, p3, position = "top")
plot_final = insert_yaxis_grob(plot_final, p2, position = "right")
ggdraw(plot_final)

ggsave("figures/03_DEM.png", width = 8, height = 6, bg = "white")
