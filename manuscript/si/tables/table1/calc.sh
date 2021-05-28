#!/bin/bash

for protocol in {shape,pharm}; do
    for cutoff in {1,5,200}; do
        for target in `cat list.txt`; do
            echo -n "${target} ${protocol} ${cutoff} "
            grep -v target results.txt \
                | grep "^$target " \
                | awk -v cutoff=${cutoff} -v protocol=${protocol} '{if ($5<=cutoff && $6==protocol) print $4}' \
                | sort -g \
                | head -n 1
        done
    done
done
