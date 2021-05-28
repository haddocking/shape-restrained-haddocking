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

if [ ! $# -eq 1 ]; then
    echo 'You should provide the run id'
fi

shopt -s expand_aliases
PATH="${PATH}:/home/enmr/software/bin/"

for target in [a-z]*/; do
    echo $target
    name=${target%/*}

    if [ ! -f "${target}/run${1}/haddock.out" ]; then
        echo 'This one has not even started yet. Skip.'
        continue
    fi
    if [ ! -f "${target}/run${1}/structures/it1/water/file.list" ]; then
        echo 'This one has started but has not finished yet. Skip.'
        continue
    fi
    if [ -f "../results/${1}/${name}.txt" ]; then
        echo 'This one has finished but is already analysed. Skip.'
        continue
    fi
    if [ -f "${target}/run${1}/structures/tmp" ]; then
        echo ' This one has finished but is already being analysed. Skip.'
        continue
    fi

    echo "Analysing run for ${target}:" `date`

    cd ${target}/run${1}/structures

    bname=${target%/*}
    echo $bname
    
    python3 ~pkoukos/git/haddock-ligand-DB/code/ligdist.py -lig UNK -f atom ../../../../structures/${bname}/bound.pdb > tmp
    echo "atoms C,CA,N,O" > profit
    python3 ~pkoukos/git/haddock-ligand-DB/code/dist_to_izone.py tmp | grep -v B >> profit
    echo "fit" >> profit
    echo "write out.pdb" >> profit

    n_it0=`ls -1 it0/*pdb | wc -l`
    n_it1=`ls -1 it1/*pdb | wc -l`
    n_itw=`ls -1 it1/water/*pdb | wc -l`
    
    echo $n_it0 $n_it1 $n_itw
    cat /dev/null > list

    for i in `seq 1 ${n_it0}`; do
        mobile="it0/complex_${bname}_${i}.pdb"
        grep -v 'H  $' $mobile  > no_h.pdb
        profit -f profit ../../../../${bname}/bound.pdb no_h.pdb >/dev/null
        grep " B " out.pdb > "${bname}_it0_${i}.pdb"
        echo "${bname}_it0_${i}.pdb" >> list
    done

    for i in `seq 1 ${n_it1}`; do
        mobile="it1/complex_${bname}_${i}.pdb"
        grep -v 'H  $' $mobile > no_h.pdb
        profit -f profit ../../../../structures/${bname}/bound.pdb no_h.pdb >/dev/null
        grep " B " out.pdb > "${bname}_it1_${i}.pdb"
        echo "${bname}_it1_${i}.pdb" >> list
    done

    for i in `seq 1 ${n_itw}`; do
        mobile="it1/water/complex_${bname}_${i}w.pdb"
        grep -v 'H  $' $mobile > no_h.pdb
        profit -f profit ../../../../structures/${bname}/bound.pdb no_h.pdb >/dev/null
        grep " B " out.pdb > "${bname}_itw_${i}w.pdb"
        echo "${bname}_itw_${i}w.pdb" >> list
    done

    grep -v '^$' it0/file.nam | awk '{print $1,NR}' | sort -Vk1 | awk '{print $2}' > rank
    grep -v '^$' it1/file.nam | awk '{print $1,NR}' | sort -Vk1 | awk '{print $2}' >> rank
    grep -v '^$' it1/water/file.nam | awk '{print $1,NR}' | sort -Vk1 | awk '{print $2}' >> rank

    pdb_mkensemble.py `cat list` | ~pkoukos/git/haddock-ligand-DB/code/pdb_element.py | grep -v '^END$' > mobile.pdb
    grep " B " ../../../../structures/${bname}/bound.pdb > ref.pdb

    obrms mobile.pdb ref.pdb | awk '{print $3}' > rmsd
    cat rmsd
    paste list rmsd rank | sed -re "s/_(it.)_/ \1 /" -e 's/.pdb/ /' | awk '{print $1,$2,$3,$4,$5}' > /trinity/login/mreau/pharmacophore_docking/results/${1}/${bname}.txt

    rm tmp list rank rmsd ${bname}*.pdb

    cd /trinity/login/mreau/pharmacophore_docking/runs/

    # Only start one at a time but run the cronjob more frequently
    #exit 0
done
