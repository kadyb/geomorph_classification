library("stars")
library("ggplot2")

names = c("Jelenia Góra", "Katowice", "Kraków Zachodni", "Kutno",
          "Nowy Targ", "Świnoujście", "Tomaszów Lubelski", "Toruń")
names = as.factor(names)

maps = list.files("data/raster_maps", pattern = "\\.tif$", full.names = TRUE)
rds = list.files("code/ALE_test/rds", pattern = "\\.rds$", full.names = TRUE)
output = data.frame(class = factor(), var = factor(), y = double(), Freq = integer())

for (i in seq_along(names)) {

  ## class frequency
  class = read_stars(maps[i], proxy = FALSE)
  class[[1]] = as.integer(class[[1]])
  class = as.vector(class[[1]])
  freq = as.data.frame(table(class))
  freq$name = names[i]

  ## ALE range
  df = readRDS(rds[i])
  rang = aggregate(y ~ var + class2, df, FUN = \(x) max(x) - min(x))
  rang = merge(rang, freq, by.x = "class2", by.y = "class")
  colnames(rang)[1] = "class"

  output = rbind(output, rang)

}

## remove outlier in Katowice
idx = which(output$name == "Katowice" & output$Freq == 6)
output = output[-idx, ]


ggplot(output, aes(log(Freq), y)) +
  geom_point(aes(colour = var), alpha = 0.8, stroke = 0) +
  geom_line(stat = "smooth", method = "loess", formula = "y ~ x", color = "black", alpha = 0.8) +
  facet_wrap(vars(name), scales = "free_x") +
  scale_colour_brewer(palette = "Dark2", name = "Variable") +
  ylim(c(0, 2)) +
  xlab("Landform representativeness (log)") +
  ylab("ALE range") +
  theme_bw() +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black"),
        axis.line = element_line(colour = "black", linewidth = 0.5),
        axis.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, vjust = 0.5),
        strip.background = element_rect(fill = NA, colour = NA))

ggsave("figures/08_ALE_range.png", width = 8, height = 5)
