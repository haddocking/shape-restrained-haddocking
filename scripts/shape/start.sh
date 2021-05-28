#!/bin/bash

bname=$(basename `pwd`)

if [ "$bname" != "runs" ]; then
    echo "You should run this in 'runs'"
    exit 1
fi

shopt -s expand_aliases
source ${HOME}/software/haddock-2.4-2021.01/haddock_configure.sh

PATH="${PATH}:/home/enmr/software/bin/"

username=`whoami`
counter=`ps -fu $username | /bin/grep python | /bin/grep -c RunHaddock`

maxrun=15

date

for target in [a-z]*; do
    if [ "$counter" -lt "$maxrun" ]; then
        # If we can afford to start a run
        if [ ! -f "${target}/run1/haddock.out" ]; then
            # Start this one as it hasn't started yet and quit
            # through increasing the counter.
            echo "Launching run for ${target}"

            cd "${target}/run1/"
            haddock2.4 &> haddock.out &
            ((counter+=1))
            cd ../../
        else
            # This particular run has started.
            if [ ! -f "${target}/run1/structures/it1/file.nam" ]; then
                # but looks like it's not finished yet. Check for status

                # Check for the bad topology
                check=`tail -100 "${target}/run1/haddock.out" | grep -c 'Error in the topology generation'`
                if [ "$check" -gt "0" ]; then
                    # Topo/para problem with this one. Skip for now without
                    # increasing the counter. Will be flagged by the check
                    # script for manual correction.
                    continue
                fi

                # Check for failed structures in it0
                check=`tail -100 "${target}/run1/haddock.out" | grep -c 'failed structures in it0'`
                if [ "$check" -gt "0" ]; then
                    # Failed structures in it0. Clean and restart
                    echo "Run ${target} has failed at it0 - restarting"

                    cd "${target}/run1/"
                    ./tools/haddock-clean
                    rm -f FAILED run_newseed.cns

                    haddock2.4 &> haddock.out &
                    ((counter+=1))
                    cd ../../
                    continue
                fi

                # Check for failed structures in it1
                check=`tail -100 "${target}/run1/haddock.out" | grep -c 'failed structures in it1' | grep -c '>20%'`
                if [ "$check" -gt "0" ]; then
                    # > 20% failed structures in it1. Something's wrong enough
                    # that restarting won't help. This usually means bad structures.
                    # Just ignore it altogether.
                    continue
                fi

                # Check for failed structures in it1
                check=`tail -100 "${target}/run1/haddock.out" | grep -c 'failed structures in it1'`
                if [ "$check" -gt "0" ]; then
                    # Failed structures in it1. Clean and restart
                    echo "Run ${target} has failed at it1 - restarting"

                    cd "${target}/run1/"
                    ./tools/haddock-clean
                    rm -f FAILED run_newseed.cns run_lowtad.cns

                    haddock2.4 &> haddock.out &
                    ((counter+=1))
                    cd ../../
                    continue
                fi

                now=`date +%s`
                last_mod_time=`date -r ${target}/run1/haddock.out +%s`
                time_diff=$(( $now - $last_mod_time ))

                if [ "$time_diff" -gt "3600" ]; then
                    # It seems this one has stopped for no apparent reason. Kill the haddock process, clean everything, wait a bit and restart.
                    echo "Run ${target} has stalled for $(($time_diff / 3600)) hours - restarting"

                    cd "${target}/run1/"
                    touch CANCEL
                    sleep 10
                    rm -f FAILED CANCEL run_newseed.cns run_lowtad.cns ${target}_*

                    haddock2.4 &> haddock.out &
                    ((counter+=1))
                    cd ../../
                    continue
                fi

                # HADDOCK process has stopped but run hasn't finished. Check for crashes in a
                # generic way. These two checks are here to catch anything that slips through
                # the previous checks.
                check=`tail -1000 "${target}/run1/haddock.out" | grep -ci finishing`
                if [ "$check" -gt "0" ]; then
                    echo "Detecting crashed run for ${target} - restarting"

                    cd "${target}/run1/"
                    ./tools/haddock-clean
                    rm -f FAILED

                    haddock2.4 &> haddock.out &
                    ((counter+=1))
                    cd ../../
                else
                    check=`tail -1000 "${target}/run1/haddock.out" |grep -i thread |grep -iv exception |grep -v File |wc -l |awk '{print $1}'`
                    if [ "$check" -gt "0" ]; then
                        echo "Detecting crashed run for ${target} - restarting"

                        cd "${target}/run1/"
                        ./tools/haddock-clean
                        rm -f FAILED

                        haddock2.4 &> haddock.out &
                        ((counter+=1))
                        cd ../../
                    else
                        # Run is already launched. Do nothing
                        :
                    fi
                fi
            else
                # Run has already finished. Do nothing
                :
            fi
        fi
    else
        echo "Maximum number of runs ("$maxrun") reached - stopping"
        date
        exit
    fi
done

date
