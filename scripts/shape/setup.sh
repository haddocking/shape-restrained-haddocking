#!/bin/bash

bname=$(basename `pwd`)

if [ "$bname" != "runs" ]; then
    echo "You should run this in 'runs'"
    exit 1
fi

shopt -s expand_aliases
source ${HOME}/software/haddock-2.4-2021.01/haddock_configure.sh

for target in [a-z]*; do
    if [[ "$target" =~ "_low" ]]; then
        low_sim="low_sim_"
    else
        low_sim=""
    fi

    cd $target

    target=`echo $target | sed -e 's/_low//'`

    n_conf=`ls -1 ../../conformers/${target}/*pdb | wc -l`

    ls -1 ../../conformers/${target}/*pdb > conformers.list

    cp ../../setup/shape/run.param .

    sed -i \
        -e "s/TARGET/${target}/g" \
        -e "s/LOW_SIM_/${low_sim}/" \
        -e "s+HOME+${HOME}+" \
        run.param

    haddock2.4

    cp ../../toppar/${target}/* run1/toppar

    cd run1
    curr_dir=`pwd`

    diff -u run.cns ../../../setup/shape/run.cns > patch_file
    patch < patch_file
    rm patch_file

    n_it0=$(( $n_conf * 20 ))

    if [ "$n_conf" -lt "10" ]; then
      n_it1=$n_it0
      n_itw=$n_it0
    else
      n_it1=200
      n_itw=200
    fi

    sed -i \
      -e "s/FILEROOT/${target}/" \
      -e "s+RUNDIR+${curr_dir}+" \
      -e "s/LIGAND/${target}_conf_001/" \
      -e "s/LOW_SIM_/${low_sim}/" \
      -e "s+HOME+${HOME}+" \
      -e "s/structures_0\=/structures_0\=${n_it0}/" \
      -e "s/structures_1\=/structures_1\=${n_it1}/" \
      -e "s/anastruc_1\=/anastruc_1\=${n_it1}/" \
      run.cns

    cd ../../
done
