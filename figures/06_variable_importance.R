library("ggplot2")

data = read.csv("results/variable_importance.csv")
data$Feature[2] = "Median 1000 m"
data$Feature[3] = "Median 500 m"
data$Feature[5] = "St. Dev."
data$Feature[9] = "Multi-scale TPI"

ggplot(data, aes(x = Gain, y = reorder(Feature, Gain))) +
  xlab("Information gain") +
  ylab("Geomorphometric variable") +
  geom_col() +
  geom_hline(yintercept = 6.5, linetype = "dashed", color = "red") +
  theme_bw() +
  theme(panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black"),
        axis.line = element_line(colour = "black", linewidth = 0.5),
        axis.title = element_text(face = "bold"))

ggsave("figures/06_variable_importance.png", width = 7, height = 4)
