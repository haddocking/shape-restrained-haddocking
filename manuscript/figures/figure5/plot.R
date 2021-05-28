#!/usr/bin/env Rscript

args = c(
  'results.txt'
)

if (length(args) == 0) {
  stop("You should provide at least one argument.")
}

library(tools)
library(tidyverse)
library(cowplot)

rmsds = read.table(args[1], header=T)

rmsds$protocol = factor(rmsds$protocol, c("shape", "pharm"))

rmsds = rmsds %>%
  filter(it0_rmsd!=Inf & it1_rmsd!=Inf)

rmsds$it0_quality = ifelse(
  rmsds$it0_rmsd<=2,
  "Acceptable",
  "Not Acceptable"
)

rmsds$it1_quality = ifelse(
  rmsds$it1_rmsd<=2,
  "Acceptable",
  "Not Acceptable"
)

rmsds$it0_quality = factor(
  rmsds$it0_quality,
  c("Acceptable", "Not Acceptable")
)
rmsds$it1_quality = factor(
  rmsds$it1_quality,
  c("Acceptable", "Not Acceptable")
)

dist_plot = ggplot(rmsds, aes(delta_rmsd, fill=protocol)) +
  geom_vline(xintercept = c(0), color='black') +
  geom_vline(xintercept = seq(-3, 5, 1), color='black', linetype='dotted') +
  geom_vline(xintercept = seq(-3.5, 4.5, 1), color='grey', linetype='dotted') +
  geom_density(alpha=0.6) +
  scale_x_continuous(
    limits=c(-3.5, 5),
    breaks=seq(-3.5, 5, 0.5)
  ) +
  theme_bw() +
  theme(
    axis.title.y = element_blank(),
    axis.ticks.y = element_blank(),
    strip.text = element_text(size=8),
    axis.text = element_text(size=7),
    axis.text.y = element_blank(),
    axis.title = element_text(size=12),
    legend.title = element_text(size=10),
    legend.text = element_text(size=8),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position = "bottom"
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.1))
  ) +
  scale_fill_manual(values=c('darkorange', 'dodgerblue')) +
  labs(
    x = "ΔRMSD [Å]"
  ) +
  facet_grid(
    . ~ it1_quality
  )

# dist_plot

ggsave(
  "delta_rmsd.png",
  dist_plot,
  width=7,
  height=4,
  dpi=300
)
