#!/bin/bash

protocol=shape

for cutoff in {200,1,4}; do
    echo -n "${protocol} ${cutoff} "
    for target in `cat list.txt`; do
        grep -v target rmsds.txt \
            | grep -v aofb \
            | grep -v casp3 \
            | grep "^$target " \
            | grep $protocol \
            | awk -v var=${cutoff} '{if ($5<=var) print $4}' \
            | sort -g \
            | head -n 1
    done | awk '{if ($1<=2.0) print}' | wc -l
done | awk '{print $0,$3/97*100}'

protocol=pharm

for cutoff in {200,1,4}; do
    echo -n "${protocol} ${cutoff} "
    for target in `cat list.txt`; do
        grep -v target rmsds.txt \
            | grep -v aofb \
            | grep -v casp3 \
            | grep "^$target " \
            | grep $protocol \
            | awk -v var=${cutoff} '{if ($5<=var) print $4}' \
            | sort -g \
            | head -n 1
    done | awk '{if ($1<=2.0) print}' | wc -l
done | awk '{print $0,$3/97*100}'
