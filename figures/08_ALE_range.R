library("stars")
library("ggplot2")

maps = list.files("data/raster_maps", pattern = "\\.tif$", full.names = TRUE)
rds = list.files("code/ALE_test/rds", pattern = "\\.rds$", full.names = TRUE)

df_output = data.frame(x = double(), y = double(), var = factor(), class = double(),
                       class2 = factor())
freq_output = data.frame(class = factor(), Freq = integer())

for (i in seq_along(maps)) {

  ## class frequency
  class = read_stars(maps[i], proxy = FALSE)
  class[[1]] = as.integer(class[[1]])
  class = as.vector(class[[1]])
  freq = as.data.frame(table(class))
  freq_output = rbind(freq_output, freq)

  ## ALE range
  df = readRDS(rds[i])
  df_output = rbind(df_output, df)

}

freq_output = aggregate(Freq ~ class, freq_output, FUN = sum)
df_output = aggregate(y ~ var + class2, df_output, FUN = \(x) max(x) - min(x))
df_output = merge(df_output, freq_output, by.x = "class2", by.y = "class")
size = sum(freq_output$Freq) # total area
df_output$km_sq = df_output$Freq * 30 * 30 / 1000 / 1000 # convert to km^2


ggplot(df_output, aes(Freq / size * 100, y)) +
  geom_point(aes(colour = var), alpha = 0.8, stroke = 0, size = 2) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "darkgrey") +
  scale_x_continuous(breaks = c(0.01, 0.1, 0.5, 1, 5, 10, 20, 30),
                     labels = c(0.01, 0.1, 0.5, 1, 5, 10, 20, 30)) +
  coord_trans(x = "log") +
  scale_colour_brewer(palette = "Dark2", name = "Variable") +
  xlab(bquote(bold("Area covered by the landform [%]"))) +
  ylab("Amplitude of the impact change") +
  theme_bw() +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black"),
        axis.line = element_line(colour = "black", linewidth = 0.5),
        axis.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, vjust = 0.5),
        strip.background = element_rect(fill = NA, colour = NA)) +
  guides(colour = guide_legend(override.aes = list(size = 2.5)))

ggsave("08_ALE_range.png", width = 8, height = 5)
