#!/bin/bash

# Stop Vagrant on failures
die () {
    echo "Unexpected error, aborting"
    echo "$*"
    #vagrant destroy
    exit 1
}
fail () {
    echo "Failed to build prefix"
    FAILED=1
}

if [ ! $# -eq 5 ]
then
    echo "Usage: $0 Vagrantfile/LOCAL KEY UN/STABLE EXTRA STAGE"
    exit 1
else
    VAGRANT_VAGRANTFILE=$1
    KEY=$2
    STABLE=$3
    EXTRA=$4
    STAGE=$5

    TIME="$(date +%Y%m%d%H%M%S)"
    # if VAGRANT_FILE is "LOCAL" 
    if [ "$VAGRANT_VAGRANTFILE" = "LOCAL" ]
    then
        # use the local system
        VAGRANTCMD="eval"
        VAGRANTREMOTE=""
        #VAGRANTSCP="scp -r "
        VAGRANTSCP="rsync -Wa -e "
        VAGRANTSCPE="ssh"
        OS="$(uname -a | sed 's/\//_/g' | sed 's/ /_/g' | sed 's/#/_/g' | sed 's/:/_/g' )"
    else
        VAGRANTCMD="vagrant ssh -c"
        VAGRANTREMOTE="default:"
        OS="$(grep "config.vm.box" $VAGRANT_VAGRANTFILE | sed 's/.*= \"\(.*\)\"/\1/' | sed 's/\//_/g' )"

        # export it to be used by vagrant
        export VAGRANT_VAGRANTFILE=$1
        # Start the VM
        vagrant up || die
        vagrant ssh-config | sed 's/Host .*/Host default/' | tee conf
        #VAGRANTSCP="scp -r -F conf "
        VAGRANTSCP="rsync -Wa -e "
        VAGRANTSCPE="ssh -l vagrant -F conf"
    fi
    SUFFIX="${STAGE}_${STABLE}_${OS}_${TIME}"
fi
FAILED=0

# Prepare prefix if not already done, this avoids changing the prefix version during separate stages
if [ ! -f bootstrap-prefix.sh ]
then
$VAGRANTCMD 'wget https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh && chmod +x bootstrap-prefix.sh' >> "full_${SUFFIX}.log" || die "Failed to download bootstrap-prefix.sh"
fi
# MD5SUM hash now before changes, mac uses md5, linux md5sum
$VAGRANTCMD 'echo "Missing md5{,sum} command" > bootstrap-prefix.md5sum || true' || die "Failed to echo missing md5sum"
$VAGRANTCMD '[[ $(command -v md5sum) ]] && md5sum "bootstrap-prefix.sh" > bootstrap-prefix.md5sum || true' || die "Failed to create md5sum"
$VAGRANTCMD '[[ $(command -v md5) ]] && md5 "bootstrap-prefix.sh" > bootstrap-prefix.md5sum || true' || die "Failed to create md5"
# if unstable, remove export STABLE_PREFIX="yes" for non interactive mode
if [ "$STABLE" = "UNSTABLE" ]
then
    # dodge macos sed -i option
    $VAGRANTCMD "sed -i.bak 's/export STABLE_PREFIX=.*//g' bootstrap-prefix.sh" >> "full_${SUFFIX}.log" || die
fi

# Copy prev stages
# does previois gentoo-prefix-stage exist?
PSTAGE=${STAGE/1/0}
PSTAGE=${PSTAGE/2/1}
PSTAGE=${PSTAGE/3/2}
PSTAGE=${PSTAGE/4/3}
if [ -d "gentoo-prefix-$PSTAGE" ]
then
    # copy it to gentoo-prefix
    ls
    $VAGRANTSCP "$VAGRANTSCPE" gentoo-prefix-$PSTAGE/* ${VAGRANTREMOTE}gentoo-prefix
    echo "Copied previous $PSTAGE"
else
    echo "No previous stage found"
fi
# Start bootstrap
set -o pipefail # forward exit code from prefix to fail function, since we want to see exit tail in stdout
echo "bootstrap start"
$VAGRANTCMD "STOP_BOOTSTRAP_AFTER=${STAGE} ./bootstrap-prefix.sh \$PWD/gentoo-prefix noninteractive" | tee -a "full_${SUFFIX}.log" | tail -n100 || fail
set +o pipefail # reset pipefail
echo "bootstrap done"
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
    echo "$OS $STABLE prefix" >> "info_${SUFFIX}.log" # CRITICAL: this is used by report_v2.sh to search for already reported bugs
    echo "$($VAGRANTCMD 'uname -a')" >> "info_${SUFFIX}.log"
    echo "MD5SUM bootstrap-prefix.sh: $($VAGRANTCMD 'cat bootstrap-prefix.md5sum')" >> "info_${SUFFIX}.log"
    echo "" >> "info_${SUFFIX}.log"
    echo "Steps to reproduce the bug:" >> "info_${SUFFIX}.log"
    echo "Run the bootstrap-prefix.sh in mode $STABLE (default STABLE) for $STAGE (lower ones before)" >> "info_${SUFFIX}.log"
    echo "" >> "info_${SUFFIX}.log"
    echo "Error message:" >> "info_${SUFFIX}.log"
    echo "$(tail -n10 full_${SUFFIX}.log )" >> "info_${SUFFIX}.log"
    echo "" >> "info_${SUFFIX}.log"
    echo "Extra info:" >> "info_${SUFFIX}.log"
    echo "$EXTRA" >> "info_${SUFFIX}.log"

    #vagrant destroy
    source report_v2.sh "$OS" "$STABLE" "full_${SUFFIX}.log" "build_${SUFFIX}.log" "info_${SUFFIX}.log" "$KEY" ${STAGE}
    exit 1
else
    echo "Success to build prefix"
    # remove potential cached stage
    rm -rf "gentoo-prefix-${STAGE}"
    $VAGRANTSCP "$VAGRANTSCPE" ${VAGRANTREMOTE}gentoo-prefix/* gentoo-prefix-${STAGE}

    # useful for debugging
    pwd
    ls 

    echo "This bug seems to be resolved for $OS $STABLE prefix"  >> "info_${SUFFIX}.log" # CRITICAL: this is used by resolve_v2.sh to search for already resolved bugs
    echo ""  >> "info_${SUFFIX}.log"
    echo "System:"  >> "info_${SUFFIX}.log"
    echo "$(vagrant --version)" >> "info_${SUFFIX}.log"
    echo "$($VAGRANTCMD 'uname -a')" >> "info_${SUFFIX}.log"
    echo "MD5SUM bootstrap-prefix.sh: $($VAGRANTCMD 'cat bootstrap-prefix.md5sum')" >> "info_${SUFFIX}.log"
    echo "bootstrap-prefix.sh in mode $STABLE for $STAGE (lower ones before)" >> "info_${SUFFIX}.log"
    echo "" >> "info_${SUFFIX}.log"
    echo "Extra info:" >> "info_${SUFFIX}.log"
    echo "$EXTRA" >> "info_${SUFFIX}.log"
    source resolve_v2.sh "$OS" "$STABLE" "info_${SUFFIX}.log" "$KEY" ${STAGE}

    #vagrant destroy
    exit 0
fi
