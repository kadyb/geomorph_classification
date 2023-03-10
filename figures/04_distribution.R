library("stars")
library("ggplot2")

## vector maps must first be rasterized to run the code below
class_tab = read.csv("data/classification_table.csv")
files = list.files("data/raster_maps", pattern = ".tif", full.names = TRUE)

class_vec = integer()
for (f in files) {
  class = read_stars(f, proxy = FALSE)
  class[[1]] = as.integer(class[[1]])
  class = as.vector(class[[1]])
  class_vec = c(class_vec, class)
}
rm(class)

tab = sort(table(class_vec))
other = 999L # create new class as "other"
threshold = quantile(tab, probs = 0.80)
idx = as.numeric(names(which(tab < threshold)))
## reclassify
for (i in idx) {
  class_vec[class_vec == i] = other
}
tab = sort(table(class_vec, useNA = "always")) # include NA too
## use class names
idx = which(!names(tab) %in% c("999", NA))
idx_match = match(names(tab[idx]), class_tab$CODE)
names(tab)[idx] = class_tab$EN[idx_match]
names(tab)[is.na(names(tab))] = "Missing"
names(tab)[names(tab) == 999L] = "Other (43 landforms)" # length(idx)
## capitalize first letters
substr(names(tab), 1, 1) <- toupper(substr(names(tab), 1, 1))
tab = prop.table(tab) * 100 # change to percentage

df = as.data.frame(tab)
colnames(df)[1] = "Name"
ggplot(df, aes(Name, Freq)) +
  geom_col() +
  xlab("Landform") +
  ylab("Occurrence rate [%]") +
  scale_x_discrete(labels = scales::label_wrap(20)) +
  theme_bw() +
  theme(panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black"),
        axis.line = element_line(colour = "black", linewidth = 0.5),
        axis.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, vjust = 0.5))
