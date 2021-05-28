#!/usr/bin/env Rscript

library(reshape2)
library(scales)
library(tidyverse)
library(cowplot)

results = melt(read.table("table.txt", header=T))

colnames(results) = c('protocol', 'cutoff', 'targets')

results = results %>%
  mutate(percentage=targets/97*100)

results$cutoff = factor(results$cutoff, levels=c('top1', 'top4', 'best'))
results$protocol = factor(
  results$protocol,
  c('FlexX', 'Pharm', 'Surflex', 'Shape', 'Gold', 'Glide')
)

comparison_plot = ggplot(results, aes(cutoff, percentage, fill=protocol)) +
  geom_col(position='dodge') +
  theme_minimal_hgrid() +
  theme(
    legend.position='bottom',
    legend.justification = 'center',
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_text(size=10),
    axis.text.y = element_text(size=10),
    axis.title = element_text(size=12),
    strip.text = element_text(size=10),
    legend.title = element_text(size=12),
    legend.text = element_text(size=10),
    legend.key.size = unit(0.1, units="in"),
    axis.ticks.x = element_line(size=0.2),
    panel.grid.major = element_line(size=0.1)
  ) +
  labs(
    y='Successfully predicted (%)',
    x='Cutoff',
    fill='Protocol'
  ) +
  scale_y_continuous(
    breaks = seq(0, 100, 10),
    expand = expansion(mult = c(0, 0.01))
  ) +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  ) +
  scale_fill_manual(
    values=c('#000000', '#E69F00', '#56B4E9', '#009E73', '#0072B2', '#D55E00')
  )

ggsave("figure8.png", comparison_plot, dpi=300, width=7, height=4)
