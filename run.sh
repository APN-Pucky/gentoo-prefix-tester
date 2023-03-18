if [ ! $# -eq 3 ]
then
    echo "Usage: $0 Vagrantfile KEY UN/STABLE"
    exit 1
else
    VAGRANT_VAGRANTFILE=$1
    KEY=$2
    STABLE=$3

    TIME="$(date +%Y%m%d%H%M%S)"
    # if VAGRANT_FILE is "LOCAL" 
    if [ "$VAGRANT_VAGRANTFILE" = "LOCAL" ]
    then
        # use the local system
        VAGRANTCMD="eval"
        OS="$(uname -a | sed 's/\//_/g' | sed 's/ /_/g' | sed 's/#/_/g')"
        # incdude OS? -> nope does not change (often...)
        mkdir -p /tmp/gentoo-prefix-$TIME
        cd /tmp/gentoo-prefix-$TIME
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
# Jump start prefix
$VAGRANTCMD 'wget https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh && chmod +x bootstrap-prefix.sh' >> "full_${SUFFIX}.log" || die
# if unstable, remove export STABLE_PREFIX="yes" for non interactive mode
if [ "$STABLE" = "UNSTABLE" ]
then
    $VAGRANTCMD "sed -i 's/export STABLE_PREFIX=.*//g' bootstrap-prefix.sh" >> "full_${SUFFIX}.log" || die
fi
$VAGRANTCMD './bootstrap-prefix.sh $PWD/gentoo-prefix noninteractive' | tee "full_${SUFFIX}.log" || fail

# if failed, report
if [ $FAILED -eq 1 ]
then
    # Find out what failed
    grep -i -A 1 "Details might be found in the build log:" "full_${SUFFIX}.log" | tail -n1  | sed 's/.*portage\/\(.*\)\/temp.*/\1/' || die 
    $VAGRANTCMD "cat $(grep -i -A 1 'Details might be found in the build log:' "full_${SUFFIX}.log" | tail -n1 | sed 's/build\.log.*/build.log/' )" > "build_${SUFFIX}.log" || die 

    # Create info log
    echo "System:"  >> "info_${SUFFIX}.log"
    echo "$(vagrant --version)" >> "info_${SUFFIX}.log"
    echo "$OS" >> "info_${SUFFIX}.log"
    echo "$(vagrant ssh -c 'uname -a')" >> "info_${SUFFIX}.log"
    echo "" >> "info_${SUFFIX}.log"
    echo "Steps to reproduce the bug:" >> "info_${SUFFIX}.log"
    echo "Run the bootstrap-prefix.sh in mode $STABLE (default STABLE)" >> "info_${SUFFIX}.log"

    #vagrant destroy
    ./report.sh "$OS" "$STABLE" "full_${SUFFIX}.log" "build_${SUFFIX}.log" "info_${SUFFIX}.log" "$KEY"
    exit 1
else
    echo "Success to build prefix"
    #vagrant destroy
    exit 0
fi
