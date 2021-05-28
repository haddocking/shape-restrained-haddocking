#!/usr/bin/env Rscript

args = c(
  'rmsds-lig_lig.txt'
)

if (length(args) == 0) {
  stop("You should provide at least one argument.")
}

library(tools)
library(tidyverse)
library(cowplot)

rmsds = read.table(args[1], header=T)

rmsds$protocol = factor(rmsds$protocol, c("rdkit", "shape", "pharm"))

compound_plot = ggplot(rmsds, aes(rmsd, fill=protocol)) +
  geom_vline(xintercept = c(1, 4, 6), color='light grey') +
  geom_vline(xintercept = c(2), color='black') +
  geom_density(alpha=0.6) +
  facet_wrap(. ~ target, ncol = 13, scales='free_y') +
  theme_bw() +
  theme(
    axis.title.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.text.y = element_blank(),
    strip.text = element_text(size=9),
    panel.grid = element_blank(),
    legend.position = "bottom"
  ) +
  scale_x_continuous(breaks=c(1, 2, 4, 6)) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.1))
  ) +
  scale_fill_manual(values=c('grey', 'darkorange', 'dodgerblue')) +
  labs(
    x = "RMSD [Å]"
  )

compound_plot

ggsave(
  "figure5.png",
  compound_plot,
  width=14,
  height=8,
  units="in",
  dpi=300
)
