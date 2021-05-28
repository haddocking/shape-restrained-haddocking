#!/usr/bin/env Rscript

library(tidyverse)
library(cowplot)
library(scales)

make_legend = function(legend_plot) {
  legend_below = get_legend(
    legend_plot + 
      guides(color = guide_legend(nrow = 1)) +
      theme(
        legend.position = "bottom",
        legend.justification = c(0.5, 0.5),
        legend.key = element_rect(color='black')
      )
  )
  
  return(legend_below)
}

args = c(
  "cutoffs.txt"
)

shape_data = fromJSON('analysis/0list-shape.json')
pharm_data = read.table(
  'analysis/0list-pharm.tsv', header=T, sep='\t', comment.char=' '
)

shape_data$similarity_difficulty = ifelse(
  shape_data$tversky < 0.4,
  "Difficult",
  ifelse(
    shape_data$tversky < 0.8,
    "Intermediate",
    "Easy"
  )
)
shape_data$overlap_difficulty = ifelse(
  shape_data$overlap < 0.5,
  "Difficult",
  ifelse(
    shape_data$overlap < 0.75,
    "Intermediate",
    "Easy"
  )
)

pharm_data$similarity_difficulty = ifelse(
  pharm_data$tversky < 0.3,
  "Difficult",
  ifelse(
    pharm_data$tversky < 0.7,
    "Intermediate",
    "Easy"
  )
)
pharm_data$overlap_difficulty = ifelse(
  pharm_data$overlap < 0.5,
  "Difficult",
  ifelse(
    pharm_data$overlap < 0.75,
    "Intermediate",
    "Easy"
  )
)

difficulty_classification = bind_rows(
  shape_data %>%
    group_by(similarity_difficulty) %>%
    count() %>%
    ungroup() %>%
    mutate(protocol='shape', measure='similarity') %>%
    rename(difficulty=similarity_difficulty),
  shape_data %>%
    group_by(overlap_difficulty) %>%
    count() %>%
    ungroup() %>%
    mutate(protocol='shape', measure='overlap') %>%
    rename(difficulty=overlap_difficulty),
  pharm_data %>%
    group_by(similarity_difficulty) %>%
    count() %>% ungroup() %>%
    mutate(protocol='pharm', measure='similarity') %>%
    rename(difficulty=similarity_difficulty),
  pharm_data %>%
    group_by(overlap_difficulty) %>%
    count() %>%
    ungroup() %>%
    mutate(protocol='pharm', measure='overlap') %>%
    rename(difficulty=overlap_difficulty)
)

difficulty_classification$difficulty = factor(
  difficulty_classification$difficulty,
  c("Easy", "Intermediate", "Difficult")
)

difficulty_classification$protocol = factor(
  difficulty_classification$protocol,
  c("shape", "pharm")
)

difficulty_classification$measure = factor(
  difficulty_classification$measure,
  c("similarity", "overlap")
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

cutoffs$similarity = factor(
  cutoffs$similarity,
  c("Easy", "Intermediate", "Difficult")
)

cutoffs$overlap = factor(
  cutoffs$overlap,
  c("Easy", "Intermediate", "Difficult")
)

shape_similarity_success_rate = ggplot(
  filter(cutoffs, (cutoff!=1000 | stage=='it0') & protocol=='shape'),
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
    x='Cutoff',
    fill='Quality'
  ) +
  theme_minimal_hgrid() +
  theme(
    legend.position='none',
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    legend.key = element_rect(colour='black'),
    title = element_text(size=12)
  ) +
  scale_y_continuous(
    labels=percent,
    breaks=c(0.2, 0.4, 0.6, 0.8, 1.0),
    expand = expansion(mult = c(0, 0))
  ) +
  facet_grid(similarity ~ stage, scale='free_x', space='free') +
  geom_vline(
    data=filter(cutoffs, stage=='it0'),
    aes(xintercept=c(6.5)),
    color='black'
  ) +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  ) +
  ggtitle("\nShape protocol similarity-based success rate")

shape_overlap_success_rate = ggplot(
  filter(cutoffs, (cutoff!=1000 | stage=='it0') & protocol=='shape'),
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
    x='Cutoff',
    fill='Quality'
  ) +
  theme_minimal_hgrid() +
  theme(
    legend.position='none',
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.text.y = element_blank(),
    axis.title.y = element_blank(),
    legend.key = element_rect(colour='black'),
    title = element_text(size=12, hjust = 0.7)
  ) +
  scale_y_continuous(
    labels=percent,
    breaks=c(0.2, 0.4, 0.6, 0.8, 1.0),
    expand = expansion(mult = c(0, 0))
  ) +
  facet_grid(overlap ~ stage, scale='free_x', space='free') +
  geom_vline(
    data=filter(cutoffs, stage=='it0'),
    aes(xintercept=c(6.5)),
    color='black'
  ) +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  ) +
  ggtitle("\nShape protocol overlap-based success rate")

pharm_similarity_success_rate = ggplot(
  filter(cutoffs, (cutoff!=1000 | stage=='it0') & protocol=='pharm'),
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
    x='Cutoff',
    fill='Quality'
  ) +
  theme_minimal_hgrid() +
  theme(
    legend.position='none',
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_text(size=10),
    legend.key = element_rect(colour='black'),
    title = element_text(size=12)
  ) +
  scale_y_continuous(
    labels=percent,
    breaks=c(0.2, 0.4, 0.6, 0.8, 1.0),
    expand = expansion(mult = c(0, 0))
  ) +
  facet_grid(similarity ~ stage, scale='free_x', space='free') +
  geom_vline(
    data=filter(cutoffs, stage=='it0'),
    aes(xintercept=c(6.5)),
    color='black'
  ) +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  ) +
  ggtitle("\nPharm protocol similarity-based success rate")

pharm_overlap_success_rate = ggplot(
  filter(cutoffs, (cutoff!=1000 | stage=='it0') & protocol=='pharm'),
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
    x='Cutoff',
    fill='Quality'
  ) +
  theme_minimal_hgrid() +
  theme(
    legend.position='none',
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_text(size=10),
    axis.text.y = element_blank(),
    axis.title.y = element_blank(),
    legend.key = element_rect(colour='black'),
    title = element_text(size=12, hjust = 0.7)
  ) +
  scale_y_continuous(
    labels=percent,
    breaks=c(0.2, 0.4, 0.6, 0.8, 1.0),
    expand = expansion(mult = c(0, 0))
  ) +
  facet_grid(overlap ~ stage, scale='free_x', space='free') +
  geom_vline(
    data=filter(cutoffs, stage=='it0'),
    aes(xintercept=c(6.5)),
    color='black'
  ) +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  ) +
  ggtitle("\nPharm protocol overlap-based success rate")

difficulty_plot = ggplot(
  difficulty_classification,
  aes(protocol, n, fill=difficulty)
) +
  geom_col(position='dodge') +
  facet_grid(. ~ measure) +
  scale_fill_manual(
    values=c(
      'darkorange',
      'dodgerblue',
      'darkgrey'
    )
  ) +
  labs(
    y='Count',
    x='Protocol',
    fill='Difficulty'
  ) +
  theme_minimal_hgrid() +
  theme(
    legend.position='Bottom',
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_text(size=10),
    legend.key = element_rect(colour='black'),
    title = element_text(size=12)
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.05))
  ) +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  ) +
  ggtitle("Difficulty grouping by\nsimilarity and overlap")

all_plots = plot_grid(
  plot_grid(
    shape_similarity_success_rate,
    shape_overlap_success_rate,
    pharm_similarity_success_rate,
    pharm_overlap_success_rate,
    nrow=2,
    ncol=2,
    rel_heights = c(0.9, 1),
    rel_widths = c(1, 0.9),
    labels = c('A', 'B', 'C', 'D')
  ),
  difficulty_plot,
  make_legend(shape_overlap_success_rate),
  make_legend(difficulty_plot),
  ncol=2,
  nrow=2,
  rel_heights = c(1, 0.1),
  rel_widths = c(1, 0.3),
  labels = c('', 'E')
)

ggsave(
  "figure7.png",
  all_plots,
  dpi=300,
  width=14,
  height=10
)
