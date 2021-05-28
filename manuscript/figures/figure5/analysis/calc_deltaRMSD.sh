#!/bin/bash

echo "target model it0_rmsd it1_rmsd delta_rmsd protocol" > results.txt

for protocol in {shape,pharm}; do
    for target in `awk '{print $1}' rmsds.txt | sort | uniq`; do
        grep $protocol rmsds.txt \
            | grep "$target it0 " \
            | sort -gk5 \
            | awk '{print $4}' \
            > it0
        grep $protocol rmsds.txt \
            | grep "$target it1 " \
            | sort -gk3 \
            | awk '{print $4}' \
            > it1

        paste it0 it1 \
            | awk -v target=${target} -v protocol=${protocol} '{print target,NR,$1,$2,$1-$2,protocol}' \
            >> results.txt
    done
done

rm it0 it1
