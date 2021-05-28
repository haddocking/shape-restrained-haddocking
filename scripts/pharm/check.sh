#!/bin/bash

for target in [a-z]*; do
    if [ ! -f "${target}/run${1}/haddock.out" ]; then
        continue
    else
        # Run has started.
        if [ ! -f "${target}/run${1}/structures/it1/water/file.nam" ]; then
            check=`tail -100 "${target}/run${1}/haddock.out" | grep -c 'Error in the topology generation'`
            if [ "$check" -gt "0" ]; then
                echo "Run for ${target} has topo/para issues"
                continue
            fi

            check=`tail -100 "${target}/run${1}/haddock.out" | grep -c 'HADDOCK cannot continue'`
            if [ "$check" -gt "0" ]; then
                echo "Run for ${target} failed"
                continue
            fi

            # Run hasn't finished yet. Check if it has crashed"
            check=`tail -1000 "${target}/run${1}/haddock.out" | grep -ci finishing`
            if [ "$check" -gt "0" ]; then
                echo "Run for ${target} crashed"
            else
                check=`tail -1000 "${target}/run${1}/haddock.out" |grep -i thread |grep -iv exception |grep -v File |wc -l |awk '{print $1}'`
                if [ "$check" -gt "0" ]; then
                    echo "Run for ${target} crashed"
                else
                    echo "Run for ${target} launched"
                fi
            fi
        else
            if [ -f "${target}/run${1}/structures/it1/analysis/cluster.out.gz" ]; then
                echo "Run for ${target} clustered"
                continue
            else
                echo "Run for ${target} finished"
            fi
        fi
    fi
done

echo '-----------------------------'
date
echo

name=${1#*_}

done_runs=`grep -c clustered .check_${name}.log`
fini_runs=`grep -c finished .check_${name}.log`

total_runs=$(( $done_runs + $fini_runs ))

echo "Clustered runs: $done_runs"
echo "Finished runs: $total_runs"
echo "Topo issues:" `grep -c topo .check_${name}.log`
echo "Currently running:" `grep -c launched .check_${name}.log`
echo "Failed:" `grep -c failed .check_${name}.log`
echo "Crashed:" `grep -c crashed .check_${name}.log`
