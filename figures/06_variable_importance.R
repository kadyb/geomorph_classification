library("ggplot2")

data = read.csv("results/variable_importance.csv")
ggplot(data, aes(x = Gain, y = reorder(Feature, Gain))) +
  xlab("Gain") +
  ylab("Feature") +
  geom_col() +
  geom_hline(yintercept = 6.5, linetype = "dashed", color = "red") +
  theme_bw() +
  theme(panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black"),
        axis.line = element_line(colour = "black", linewidth = 0.5),
        axis.title = element_text(face = "bold"))
