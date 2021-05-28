#!/usr/bin/env Rscript

library(tidyverse)
library(cowplot)
library(scales)

args = c(
  "cutoffs.txt"
)

cutoffs = read.table(args[1], header=T, sep=',')

cutoffs$target = factor(cutoffs$target, levels=unique(cutoffs$target))
cutoffs$stage = factor(cutoffs$stage, levels=c('it0', 'it1'))
cutoffs$protocol = factor(cutoffs$protocol, levels=c('shape', 'pharm'))

cutoffs$quality = factor(
  cutoffs$quality,
  levels=c('Low', 'Near Acceptable', 'Acceptable', 'Medium', 'High')
)

cutoffs$cutoff = factor(
  cutoffs$cutoff,
  c(1, 5, 10, 50, 100, 200, 1000)
)

success_rate_plot = ggplot(
  filter(cutoffs, cutoff!=1000 | stage=='it0'),
  aes(cutoff, fill=quality)
) +
  geom_hline(
    yintercept = c(0.1, 0.3, 0.5, 0.7, 0.9),
    color='light grey',
    linetype='dashed'
  ) +
  geom_bar(position='fill') +
  scale_fill_manual(
    values=c(
      'transparent',
      '#d2d2d2',
      '#a6cee3',
      '#b2df8a',
      '#33a02c'
    )
  ) +
  labs(
    y='Success rate',
    x='TopN',
    fill='Quality'
  ) +
  theme_minimal_hgrid() +
  theme(
    legend.position='bottom',
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_text(size=10),
    legend.key = element_rect(colour='black'),
    legend.title = element_text(size=10),
    legend.text = element_text(size=8),
    legend.key.size = unit(0.1, units="in"),
    legend.justification = 'center'
  ) +
  scale_y_continuous(
    labels=percent,
    breaks=c(0.2, 0.4, 0.6, 0.8, 1.0),
    expand = expansion(mult = c(0, 0))
  ) +
  facet_grid(protocol ~ stage, scale='free_x', space='free') +
  geom_vline(
    data=filter(cutoffs, stage=='it0'),
    aes(xintercept=c(6.5)),
    color='black'
  ) +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  )

ggsave(
  "figure2.png",
  success_rate_plot,
  dpi=300,
  width=7,
  height=4
)
