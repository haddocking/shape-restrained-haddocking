#!/usr/bin/env Rscript

library(tidyverse)
library(cowplot)
library(jsonlite)

args = c(
  "rmsds_filtered.txt"
)

shape_data = fromJSON('../0list.json')
pharm_data = read.table('../0list-pharm.tsv', header=T, sep='\t', comment.char=' ')

rmsds = read.table(args[1], header=T, sep=" ")

rmsds$target = factor(rmsds$target, levels=unique(rmsds$target))
rmsds$stage = factor(rmsds$stage, levels=c('it0', 'it1'))

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
  levels=c('Low', 'Near Acceptable', 'Acceptable', 'Medium', 'High')
)

list_of_cutoffs = ifelse(
  max(rmsds$rank) <= 50,
  list(c(1, 5, 10, 50)),
  ifelse(
    max(rmsds$rank) <= 100,
    list(c(1, 5, 10, 50, 100)),
    ifelse(
      max(rmsds$rank) <= 200,
      list(c(1, 5, 10, 50, 100, 200)),
      list(c(1, 5, 10, 50, 100, 200, 1000))
    )
  )
)[[1]]

cutoffs = lapply(
  unique(rmsds$target),
  function (this_target) {
    lapply(
      list_of_cutoffs,
      function(this_cutoff) {
        lapply(
          c("it0", "it1"),
          function(this_stage) {
            lapply(
              c('shape', 'pharm'),
              function(this_protocol) {
                filter(rmsds,
                       target == this_target &
                         rank <= this_cutoff &
                         stage == this_stage &
                         protocol == this_protocol
                ) %>%
                  select(
                    target,
                    rmsd,
                    stage,
                    protocol
                  ) %>%
                  mutate(
                    quality=ifelse(
                      min(rmsd) <= 0.5,
                      "High",
                      ifelse(
                        min(rmsd) <= 1,
                        "Medium",
                        ifelse(
                          min(rmsd) <= 2,
                          "Acceptable",
                          ifelse(
                            min(rmsd) <= 2.5,
                            "Near Acceptable",
                            "Low"
                          )
                        )
                      )
                    ),
                    cutoff=this_cutoff
                  ) %>%
                  ungroup() %>%
                  select(!rmsd) %>%
                  distinct()
              }
            )
          }
        )
      }
    )
  }
)

cutoffs = map_dfr(unlist(unlist(cutoffs, recursive=F), recursive=F), cbind)

cutoffs$quality = factor(
  cutoffs$quality,
  c("Low", "Near Acceptable", "Acceptable", "Medium", "High")
)

cutoffs$cutoff = factor(
  cutoffs$cutoff,
  list_of_cutoffs
)

write.table(
  cutoffs,
  "../other.txt",
  sep=',',
  row.names=F,
  quote = F
)
