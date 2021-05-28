#!/bin/bash

bname=$(basename `pwd`)

if [ "$bname" != "runs" ]; then
    echo "You should run this in 'runs'"
    exit 1
fi

for target in [a-z]*; do
    if [ ! -f "${target}/run${1}/haddock.out" ]; then
        continue
    elif [ -f "${target}/run${1}/structures/it1/analysis/cluster.out.gz" ]; then
        continue
    else
        it0=`ls ${target}/run${1}/structures/it0/*pdb 2> /dev/null | wc -l `
        it1=`ls ${target}/run${1}/structures/it1/*pdb 2> /dev/null | wc -l `

        max_it0=`grep structures_0= ${target}/run${1}/run.cns | sed -e 's/structures_0=//' -e 's/;//' | awk '{print $2}'`
        echo $target ${it0}/${max_it0} $it1
    fi
done
