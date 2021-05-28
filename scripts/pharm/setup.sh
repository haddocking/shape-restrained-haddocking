#!/bin/bash

## This is for local HADDOCK
shopt -s expand_aliases
source /trinity/login/pkoukos/software/haddock-2.4-2021.01/haddock_configure.sh

PATH="${PATH}:/home/enmr/software/bin/"

if [ "$#" != 2 ]; then
    echo "Usage: ${0##*/} run_ID <number_of_conformers>"
    exit 1
fi

for target in [a-z]*; do

      if [ -f "${target}/run${1}/structures/it1/water/file.nam" ]; then
	  continue
      fi

    mkdir ${target}
    cd ${target}/
    
    ID=${target#*_}
    rm -r run$1 run_$1

    cp ../../setup/run.param.$1 run.param

    sed -i \
      -e "s/COMPLEX/${target}/g"\
      -e "s/ZZ/${1}/"\
    run.param

    n_conf=`ls -1 ../../conformers/${target}/*pdb | wc -l`
    ls -1 ../../conformers/${target}/${target}*pdb > conformers.list

    haddock2.4
    
    mkdir run${1}
    cd run${1}

    cp ../../../toppar/${target}/* toppar/

    curdir=`pwd`

    diff -u run.cns ../../../setup/run.cns.$1 > patch_file

    patch < patch_file
    rm patch_file

    python3 /trinity/login/mreau/scripts/python/add_his_protonation.py run.cns ../../../receptors/${target}/HIS/${target}.HIS
    mv run.cns.tmp run.cns

    n_it0=$(( $n_conf * 20 ))

    if [ "$n_conf" -lt "10" ]; then
      n_it1=$n_it0
      n_itw=$n_it0
    else
      n_it1=200
      n_itw=200
    fi

    sed -i \
      -e "s/FILEROOT/complex_${target}/"\
      -e "s+RUNDIR+${curdir}+"\
      -e "s/COMPLEX/${target}/"\
      -e "s/structures_0\=/structures_0\=${n_it0}/"\
      -e "s/structures_1\=/structures_1\=${n_it1}/"\
      -e "s/anastruc_1\=/anastruc_1\=${n_it1}/"\
      -e "s/waterrefine\=\;/waterrefine\=${n_itw}\;/"\
      -e "s/solvshell=true/solvshell=false/g"\
      -e "s/delenph=false/delenph=true/g"\
    run.cns

    sed -i -e 's/set_occupancy\=true\;/set_occupancy\=false\;/g' protocols/generate.inp
    sed -i -e 's/set_occupancy\=true\;/set_occupancy\=false\;/g' protocols/generate-water.inp

    sed -i -e 's/do (b\=10) (all)/\!do (b=10) (all)/g' protocols/generate_complex.inp
    sed -i -e 's/do (q\=1) (all)/\!do (q=1) (all)/g' protocols/generate_complex.inp

    cd ../../
  done 

#else
#  echo "Usage: provide one argument"
#fi
