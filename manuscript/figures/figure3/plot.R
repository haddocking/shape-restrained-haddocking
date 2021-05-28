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
library(jsonlite)

target_data = fromJSON('0list.json')
pharm_data = read.table(
  '0list-pharm.tsv',
  header=T, sep='\t',
  comment.char = ""
) %>%
  select(!target) %>%
  rename(target=prot)

templates = target_data %>%
  select(target, overlap, tversky) %>%
  rename(similarity=tversky) %>%
  mutate(protocol="shape")

pharm_templates = pharm_data %>%
  select(target, overlap, tversky) %>%
  rename(similarity=tversky) %>%
  mutate(protocol="pharm")

all_templates = bind_rows(templates, pharm_templates)

rmsds = read.table(args[1], header=T, sep=" ")
rmsds = filter(rmsds, stage == 'it1')

rmsd_fname = file_path_sans_ext(args[1])
parameters = str_split(rmsd_fname, "-")[[1]]

rmsds = rmsds %>% mutate(
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

rmsds$quality = factor(
  rmsds$quality,
  c("Low", "Near Acceptable", "Acceptable", "Medium", "High")
)

rmsds$target = factor(
  rmsds$target,
  templates$target
)

rmsds$protocol = factor(rmsds$protocol, c("shape", "pharm"))
all_templates$protocol = factor(all_templates$protocol, c("shape", "pharm"))

sim_plot = ggplot(
  all_templates,
  aes(
    target,
    similarity,
    fill=protocol
  )
) +
  geom_col(position='dodge') +
  geom_point(
    data=all_templates,
    aes(
      target,
      overlap,
      color=protocol),
    position = position_dodge(width=1),
    size=0.3
  ) +
  theme_minimal_hgrid() +
  scale_fill_manual(values=c('darkorange', 'dodgerblue')) +
  scale_color_manual(values=c('#009E73', '#D55E00')) +
  theme(
    legend.position='bottom',
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    legend.justification = 'center',
    axis.text.y = element_text(size=6),
    axis.title = element_text(size=8),
    strip.text = element_text(size=6),
    legend.title = element_text(size=8),
    legend.text = element_text(size=6),
    legend.key.size = unit(0.1, units="in"),
    axis.ticks.x = element_line(size=0.1),
    panel.grid.major = element_line(size=0.1)
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.05))
  ) +
  geom_vline(xintercept = seq(1,98) + 0.5, col='#555555', size=0.05) +
  geom_vline(xintercept = seq(1,99), col='#bcbcbc', size=0.05) +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  ) +
  labs(
    y='Similarity',
    fill='Protocol',
    colour='Protocol'
  )

mel_plot = ggplot(rmsds, aes(target, rank, fill=quality)) +
  geom_tile() +
  geom_vline(xintercept = seq(1,98) + 0.5, col='#555555', size=0.05) +
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
    axis.ticks = element_line(color='black'),
    strip.background = element_rect(fill='grey', color='grey'),
    panel.border = element_rect(color='black', fill=NA),
    axis.text.x = element_text(angle=90, vjust=0.5, size=4),
    legend.key = element_rect(colour='black'),
    legend.justification = 'center',
    axis.text.y = element_text(size=6),
    axis.title = element_text(size=8),
    strip.text = element_text(size=6),
    legend.title = element_text(size=8),
    legend.text = element_text(size=6),
    legend.key.size = unit(0.1, units="in"),
    axis.ticks.x = element_line(size=0.1),
    panel.grid.major = element_line(size=0.1)
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.05))
  ) +
  facet_grid('protocol ~ .') +
  guides(
    fill=guide_legend(title.position = 'top', title.hjust = 0.5)
  ) +
  labs(
    y='Rank',
    x='Target',
    fill='Quality'
  )

both = plot_grid(
  sim_plot,
  mel_plot,
  nrow=2,
  align='v',
  axis='lr',
  rel_heights = c(0.45, 1)
)

ggsave("figure3.png", both, width=7, height=4, dpi=300)
