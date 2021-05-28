#!/usr/bin/env Rscript

library(tidyverse)

c_rmsds = read.table("conformers_rmsd.txt", header=T, sep=" ")

c_rmsds = filter(c_rmsds, parameters=='3sr' & minimisation=='yes')

distribution_plot = ggplot(filter(c_rmsds, conformer <= cap_50), aes(rmsd)) +
  geom_vline(xintercept = c(1, 4, 6), color='light grey') +
  geom_vline(xintercept = c(2), color='darkorange') +
  geom_density(fill='dodgerblue') +
  facet_wrap(. ~ target, ncol = 13, scales='free_y') +
  theme_bw() +
  theme(
    axis.title.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.text.y = element_blank(),
    strip.text = element_text(size=9),
    panel.grid = element_blank()
  ) +
  scale_x_continuous(breaks=c(1, 2, 4, 6)) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.1))
  ) +
  labs(
    x = "RMSD [Å]"
  )

ggsave("figure2.png", distribution_plot, width=14, height=8, units="in", dpi=300)
