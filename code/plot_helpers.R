#!/usr/bin/env Rscript

library(scales)
library(tidyverse)
library(cowplot)

make_melquiplot = function(results_df, faceting_var) {
  melquiplot = ggplot(results_df, aes(target, rank, fill=quality)) +
    geom_tile() +
    geom_vline(xintercept = seq(0,100) + 0.5, col='light grey') +
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
      legend.position='none',
      axis.ticks = element_line(color='black'),
      strip.background = element_rect(fill='grey', color='grey'),
      panel.border = element_rect(color='black', fill=NA),
      axis.text.x = element_text(angle=90, vjust=0.5, size=9)
    ) +
    scale_y_continuous(
      expand = expansion(mult = c(0, 0.05))
    ) +
    facet_grid(
      paste('stage ~ ', faceting_var, sep=''),
      scales='free', space='free_x'
    )

  if (max(results_df$rank) > 200) {
    melquiplot = melquiplot + geom_hline(
      data=filter(results_df, stage=='it0'),
      aes(yintercept = c(200)),
      color='black'
    )
  }

  return(melquiplot)
}

make_tile_plot = function(cutoff_df) {
  tile_plot = ggplot(cutoff_df, aes(cutoff, target, fill=quality)) +
    geom_tile() +
    geom_vline(xintercept = seq(1, 6) + 0.5, color='grey') +
    facet_grid(label ~ stage, scales='free_x') +
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
      legend.position='none',
      axis.ticks.x = element_line(color='black'),
      panel.grid = element_blank(),
      strip.background = element_rect(fill='grey', color='grey'),
      panel.border = element_rect(color='black', fill=NA)
    )
  
  return(tile_plot)
}

make_success_rate_plot = function(cutoff_df) {
  success_rate_plot = ggplot(cutoff_df, aes(cutoff, fill=quality)) +
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
      y='Success rate'
    ) +
    theme_minimal_hgrid() +
    theme(
      legend.position='none',
      axis.ticks = element_line(color='black'),
      strip.background = element_rect(fill='grey', color='grey'),
      panel.border = element_rect(color='black', fill=NA),
      axis.text.x = element_text(angle=45, size=9)
    ) +
    scale_y_continuous(
      labels=percent,
      breaks=c(0.2, 0.4, 0.6, 0.8, 1.0),
      expand = expansion(mult = c(0, 0))
    )

  if (max(as.integer(as.vector(unique(cutoff_df$cutoff)))) > 200) {
    success_rate_plot = success_rate_plot + geom_vline(
      data = filter(cutoff_df, stage=='it0'),
      aes(xintercept = c(6.5)),
      color='black'
    )
  }
  
  return(success_rate_plot)
}

make_percentage_plot = function(percentage_df) {
  percentage_plot = ggplot(percentage_df, aes(cutoff, perc, fill=quality)) +
    geom_hline(
      yintercept = c(0.1, 0.3, 0.5, 0.7, 0.9),
      color='light grey',
      linetype='dashed'
    ) +
    geom_col() +
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
      y='Percentage of model quality'
    ) +
    theme_minimal_hgrid() +
    theme(
      legend.position='none',
      axis.ticks = element_line(color='black'),
      strip.background = element_rect(fill='grey', color='grey'),
      panel.border = element_rect(color='black', fill=NA),
      axis.text.x = element_text(angle=45, size=9)
    ) +
    scale_y_continuous(
      labels=percent,
      breaks=c(0.2, 0.4, 0.6, 0.8, 1.0),
      expand = expansion(mult = c(0, 0))
    )

  if (max(as.integer(as.vector(unique(percentage_df$cutoff)))) > 200) {
    percentage_plot = percentage_plot + geom_vline(
      data = filter(percentage_df, stage=='it0'),
      aes(xintercept = c(6.5)),
      color='black'
    )
  }

  return(percentage_plot)
}

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

make_title = function(title_text) {
  title = ggdraw() + 
    draw_label(
      title_text,
      fontface = 'bold',
      x = 0,
      hjust = 0
    ) +
    theme(
      plot.margin = margin(0, 0, 0, 7, unit = 'in')
    )

  return(title)
}