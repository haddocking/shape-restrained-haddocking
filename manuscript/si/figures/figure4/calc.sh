#!/bin/bash

for protocol in {high,low}; do
    for cutoff in {1,5,200}; do
        echo -n "${protocol} ${cutoff} "
        for target in `cat list.txt`; do
            grep -v target shape.txt \
                | grep it1 \
                | grep "^$target " \
                | awk -v cutoff=${cutoff} -v protocol=${protocol} '{if ($5<=cutoff && $7==protocol) print $4}' \
                | sort -g \
                | head -n 1
        done | awk '{if ($1<=2.0) print}' | wc -l
    done
done | awk '{print $0,$3/34*100}'
