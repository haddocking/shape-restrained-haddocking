#!/bin/bash

username=`whoami`
ncount=`ps -fu $username | /bin/grep analyse | /bin/grep -c bash`

if [ "$ncount" -ge "10" ]; then
    # There are enough analysis scripts running at the moment
    exit 0
fi

bname=$(basename `pwd`)

if [ "$bname" != "runs" ]; then
    echo "You should run this in 'runs'"
    exit 1
fi

PATH="${PATH}:/home/enmr/software/bin/"

for target in [a-z]*; do
    if [ ! -f "${target}/run1/haddock.out" ]; then
        # This one hasn't even started yet. Skip.
        continue
    fi
    if [ ! -f "${target}/run1/structures/it1/analysis/cluster.out.gz" ]; then
        # This one has started but hasn't finished yet. Skip.
        continue
    fi
    if [ -f "../results/docking/${target}.txt" ]; then
        # This one has finished but is already analysed. Skip.
        continue
    fi
    if [ -f "${target}/run1/structures/tmp" ]; then
        # This one has finished but is already being analysed. Skip.
        continue
    fi

    echo "Analysing run for ${target}:" `date`

    cd ${target}/run1/structures

    bname=`echo $target | sed -e 's/_low//'`

    ../../../../.venv/bin/python ../../../../code/ligdist.py -lig UNK -f atom ../../../../structures/${bname}/bound.pdb > tmp

    echo "atoms C,CA,N,O" > profit

    ../../../../.venv/bin/python ../../../../code/dist_to_izone.py tmp | grep -v B >> profit

    echo "fit" >> profit
    echo "write out.pdb" >> profit

    n_it0=`ls -1 it0/*pdb | wc -l`
    n_it1=`ls -1 it1/*pdb | wc -l`

    cat /dev/null > list

    for i in `seq 1 ${n_it0}`; do
        mobile="it0/${bname}_${i}.pdb"
        grep -v 'H  $' $mobile > no_h.pdb
        profit -f profit ../../../../structures/${bname}/bound.pdb no_h.pdb >/dev/null
        grep " B " out.pdb > "${target}_it0_${i}.pdb"
        echo "${target}_it0_${i}.pdb" >> list
    done

    for i in `seq 1 ${n_it1}`; do
        mobile="it1/${bname}_${i}.pdb"
        grep -v 'H  $' $mobile > no_h.pdb
        profit -f profit ../../../../structures/${bname}/bound.pdb no_h.pdb >/dev/null
        grep " B " out.pdb > "${target}_it1_${i}.pdb"
        echo "${target}_it1_${i}.pdb" >> list
    done

    grep -v '^$' it0/file.nam | awk '{print $1,NR}' | sort -Vk1 | awk '{print $2}' > rank
    grep -v '^$' it1/file.nam | awk '{print $1,NR}' | sort -Vk1 | awk '{print $2}' >> rank

    ../../../../.venv/bin/pdb_mkensemble `cat list` | ../../../../code/pdb_element.py | grep -v '^END$' > mobile.pdb
    grep " B " ../../../../structures/${bname}/bound.pdb > ref.pdb

    ../../../../.venv/bin/obrms mobile.pdb ref.pdb | awk '{print $3}' > rmsd
    paste list rmsd rank | sed -re "s/_(it.)_/ \1 /" -e 's/.pdb/ /' | awk '{print $1,$2,$3,$4,$5}' > ../../../../results/docking/${target}.txt

    rm tmp list rank rmsd profit *.pdb

    cd ../../..

    # Only start one at a time but run the cronjob more frequently
    exit 0
done
