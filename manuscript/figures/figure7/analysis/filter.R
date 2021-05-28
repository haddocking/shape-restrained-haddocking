#!/usr/bin/env Rscript

library(tidyverse)
library(cowplot)
library(jsonlite)

args = c(
  "rmsds.txt"
)

shape_data = fromJSON('../0list.json')
pharm_data = read.table('../0list-pharm.tsv', header=T, sep='\t', comment.char=' ')

rmsds = read.table(args[1], header=T, sep=" ")

rmsds = rmsds %>%
  rowwise() %>%
  mutate(
    similarity=ifelse(
      grepl('shape', protocol, fixed=T),
      shape_data[shape_data$target == target,]$tversky,
      pharm_data[pharm_data$prot == target,]$tversky
    ),
    mol_weight_diff=ifelse(
      grepl('shape', protocol, fixed=T),
      abs(
        shape_data[shape_data$target == target,]$target_lig_mol_weight -
          shape_data[shape_data$target == target,]$template_lig_mol_weight
      ),
      abs(
        pharm_data[pharm_data$prot == target,]$target_weights -
          pharm_data[pharm_data$prot == target,]$template_weights
      )
    )
  )

filtered_rmsds = rmsds %>%
  filter(
    (similarity >= 0.4 & mol_weight_diff <= 50 & protocol == 'shape') |
      (similarity >= 0.3 & mol_weight_diff <= 50 & protocol == 'pharm')
  )

filtered_rmsds$mol_weight_diff = round(filtered_rmsds$mol_weight_diff, 2)

write.table(filtered_rmsds, 'rmsds_filtered.txt', quote=F, row.names=F)
