library("ggplot2")

rds = list.files("data/rds", pattern = "\\.rds$", full.names = TRUE)

names = c("Jelenia Góra", "Katowice", "Kraków Zachodni", "Kutno",
          "Nowy Targ", "Świnoujście", "Tomaszów Lubelski", "Toruń")
names2 = c("Jelenia_Gora", "Katowice", "Krakow", "Kutno",
           "Nowy_Targ", "Swinoujscie", "Tomaszow_Lubelski", "Torun")

outdir = file.path("figures", "ALE")
if (!dir.exists(outdir)) dir.create(outdir)

for (i in seq_along(rds)) {

  ALE_df = readRDS(rds[i])

  ggplot(ALE_df, aes(x, y)) +
    geom_line() +
    geom_hline(yintercept = 0, color = "grey", linetype = "dashed", alpha = 0.6) +
    facet_grid(class2 ~ var, scales = "free", labeller = label_wrap_gen()) +
    xlab("Variable value") +
    ylab("Impact on classification probability") +
    labs(title = names[i]) +
    theme_bw() +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text = element_text(color = "black"),
      axis.line = element_line(colour = "black", linewidth = 0.5),
      axis.title = element_text(face = "bold"),
      axis.text.x = element_text(angle = 60, vjust = 0.5),
      strip.background = element_rect(fill = NA, colour = NA),
      strip.text.y = element_text(angle = 0),
      strip.text = element_text(colour = "black"),
      plot.title = element_text(hjust = 0.5, face = "bold"))


  fn = paste0("figures/ALE/", names2[i], ".png")
  ggsave(fn, width = 10, height = 13)

}
