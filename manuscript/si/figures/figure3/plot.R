#!/usr/bin/env Rscript

library(scales)
library(tidyverse)
library(cowplot)

results = read.table("results.txt", header=T)

results = results %>% mutate(
  quality=ifelse(
    rmsd<=0.5, "High", ifelse(
      rmsd<=1, "Medium", ifelse(
        rmsd<=2, "Acceptable", ifelse(
          rmsd<=2.5, "Near Acceptable", "Low"
        )
      )
    )
  )
)

results$target = factor(results$target, unique(results$target))
results$stage = factor(results$stage, c('it0', 'it1'))
results$protocol = factor(results$protocol, c('shape', 'pharm'))
results$quality = factor(
  results$quality,
  c('Low', 'Near Acceptable', 'Acceptable', 'Medium', 'High')
)

melquiplot = ggplot(results, aes(target, rank, fill=quality)) +
  geom_tile() +
  geom_vline(xintercept = seq(0,100) + 0.5, col='light grey', size=0.1) +
  scale_fill_manual(
    values=c(
      'transparent',
      '#d2d2d2',
      '#a6cee3',
      '#b2df8a',
      '#33a02c'
    )
  ) +
  theme_minimal_hgrid() +
  theme(
    legend.position='bottom',
    legend.justification = 'center',
    legend.key=element_rect(colour='black'),
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_blank(),
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
    y='Rank',
    x='Target',
    fill='Quality'
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.005))
  ) +
  facet_grid('stage ~ protocol', scales='free', space='free_x') +
  geom_hline(
    data=filter(results, stage=='it0'),
    aes(yintercept = c(200)),
    color='black',
    size=0.1
  ) +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  )

melquiplot

ggsave("figure3.png", melquiplot, dpi=300, width=7, height=4)
