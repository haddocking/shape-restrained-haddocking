#!/usr/bin/env Rscript

library(tidyverse)
library(jsonlite)
library(cowplot)

shape_templates = fromJSON("0list.json") %>%
  arrange(desc(tversky))

shape_templates$target = factor(
  shape_templates$target,
  levels = shape_templates$target
)

low_sim_shape_templates = filter(shape_templates, (!is.na(low_sim_tversky)))

pharm_templates = read.table("0list-pharm.tsv", header=T, comment.char='') %>%
  arrange(desc(tversky))

pharm_templates$target = factor(
  pharm_templates$target,
  levels = pharm_templates$target
)

shape_similarities = ggplot(shape_templates, aes(target, tversky)) +
  geom_col(fill='#1F77B4') +
  geom_point(
    data=low_sim_shape_templates,
    aes(target, low_sim_tversky),
    color='#FF7F0E',
    size=2.5
  ) +
  geom_vline(xintercept=c(35) + 0.5, size=1) +
  theme_minimal_hgrid() +
  scale_x_discrete(expand=(c(0, 1))) +
  scale_y_continuous(
    breaks=seq(0, 1.2, 0.2),
    expand=c(0, 0.01)
  ) +
  labs(
    x='',
    y='Shape Similarity'
  ) +
  theme(
    panel.grid.major.x=element_blank(),
    axis.text.x=element_blank()
  )

pharm_similarities = ggplot(pharm_templates, aes(target, tversky)) +
  geom_col(fill='#1F77B4') +
  theme_minimal_hgrid() +
  scale_x_discrete(expand=(c(0, 1))) +
  scale_y_continuous(
    breaks=seq(0, 1.2, 0.2),
    expand=c(0, 0.01),
    limits = c(0, 1.0)
  ) +
  labs(
    x='Target',
    y='Pharm Similarity'
  ) +
  theme(
    panel.grid.major.x=element_blank(),
    axis.text.x=element_blank()
  )

both = plot_grid(shape_similarities, pharm_similarities, nrow=2)

ggsave("figure1.png", both, width=14, height=8)
