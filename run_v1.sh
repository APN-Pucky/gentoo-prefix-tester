#!/bin/bash
if [ ! $# -ge 3 ]
then
    echo "Usage: $0 Vagrantfile/LOCAL KEY UN/STABLE"
    exit 1
else
    VAGRANT_VAGRANTFILE=$1
    KEY=$2
    STABLE=$3
    EXTRA=$4

    TIME="$(date +%Y%m%d%H%M%S)"
    # if VAGRANT_FILE is "LOCAL" 
    if [ "$VAGRANT_VAGRANTFILE" = "LOCAL" ]
    then
        # use the local system
        VAGRANTCMD="eval"
        OS="$(uname -a | sed 's/\//_/g' | sed 's/ /_/g' | sed 's/#/_/g' | sed 's/:/_/g' )"
    else
        VAGRANTCMD="vagrant ssh -c"
        OS="$(grep "config.vm.box" $VAGRANT_VAGRANTFILE | sed 's/.*= \"\(.*\)\"/\1/' | sed 's/\//_/g' )"

        # export it to be used by vagrant
        export VAGRANT_VAGRANTFILE=$1
        # Start the VM
        vagrant up
    fi
    SUFFIX="${STABLE}_${OS}_${TIME}"
fi
FAILED=0

# Stop Vagrant on failures
die () {
    echo "Unexpected error, aborting"
    #vagrant destroy
    exit 1
}
fail () {
    echo "Failed to build prefix"
    FAILED=1
}
# Prepate prefix
$VAGRANTCMD 'wget https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh && chmod +x bootstrap-prefix.sh' >> "full_${SUFFIX}.log" || die
# if unstable, remove export STABLE_PREFIX="yes" for non interactive mode
if [ "$STABLE" = "UNSTABLE" ]
then
    # dodge macos sed -i option
    $VAGRANTCMD "sed -i.bak 's/export STABLE_PREFIX=.*//g' bootstrap-prefix.sh" >> "full_${SUFFIX}.log" || die
fi
# Start bootstrap
set -o pipefail # forward exit code from prefix to fail function, since we want to see exit tail in stdout
$VAGRANTCMD './bootstrap-prefix.sh $PWD/gentoo-prefix noninteractive' | tee -a "full_${SUFFIX}.log" | tail -n100 || fail
set +o pipefail # reset pipefail

# if failed, report
if [ $FAILED -eq 1 ]
then
    # Find out what failed
    tail -n50 "full_${SUFFIX}.log"
    grep -i -A 1 "Details might be found in the build log:" "full_${SUFFIX}.log" | tail -n1  | sed 's/.*portage\/\(.*\)\/temp.*/\1/' #|| die 
    # Stage 1 error
    $VAGRANTCMD "cat $(grep -i 'You can find a log of what happened in' "full_${SUFFIX}.log" | sed 's/You can find a log of what happened in//' )" >> "build_${SUFFIX}.log" #|| die
    # Build error 
    $VAGRANTCMD "cat $(grep -i -A 1 'Details might be found in the build log:' "full_${SUFFIX}.log" | tail -n1 | sed 's/build\.log.*/build.log/' )" >> "build_${SUFFIX}.log" #|| die

    # Create info log
    echo "System:"  >> "info_${SUFFIX}.log"
    echo "$(vagrant --version)" >> "info_${SUFFIX}.log"
    echo "$OS $STABLE prefix" >> "info_${SUFFIX}.log"
    echo "$($VAGRANTCMD 'uname -a')" >> "info_${SUFFIX}.log"
    echo "" >> "info_${SUFFIX}.log"
    echo "Steps to reproduce the bug:" >> "info_${SUFFIX}.log"
    echo "Run the bootstrap-prefix.sh in mode $STABLE (default STABLE)" >> "info_${SUFFIX}.log"
    echo "" >> "info_${SUFFIX}.log"
    echo "Error message:" >> "info_${SUFFIX}.log"
    echo "$(tail -n10 full_${SUFFIX}.log )" >> "info_${SUFFIX}.log"
    echo "" >> "info_${SUFFIX}.log"
    echo "Extra info:" >> "info_${SUFFIX}.log"
    echo "$EXTRA" >> "info_${SUFFIX}.log"

    #vagrant destroy
    ./report_v1.sh "$OS" "$STABLE" "full_${SUFFIX}.log" "build_${SUFFIX}.log" "info_${SUFFIX}.log" "$KEY"
    exit 1
else
    echo "Success to build prefix"
    #vagrant destroy
    exit 0
fi
