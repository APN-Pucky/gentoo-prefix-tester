if [ ! $# -eq 2 ]
then
    echo "Usage: $0 Vagrantfile KEY"
    exit 1
else
    VAGRANT_VAGRANTFILE=$1
    KEY=$2
    # export it to be used by vagrant
    export VAGRANT_VAGRANTFILE=$1
fi

TIME="$(date +%Y%m%d%H%M%S)"
OS="$(grep "config.vm.box" $VAGRANT_VAGRANTFILE | sed 's/.*= \"\(.*\)\"/\1/' | sed 's/\//_/g' )"
SUFFIX="${OS}_${TIME}"
FAILED=0

# Start the VM
vagrant up
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
vagrant ssh -c 'wget https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh && chmod +x bootstrap-prefix.sh && ./bootstrap-prefix.sh $PWD/gentoo-prefix noninteractive' > full_$SUFFIX.log || fail

# if failed, report
if [ $FAILED -eq 1 ]
then
    # Find out what failed
    grep -i -A 1 "Details might be found in the build log:" full_$SUFFIX.log | tail -n1  | sed 's/.*portage\/\(.*\)\/temp.*/\1/' || die 
    vagrant ssh -c "cat $(grep -i -A 1 'Details might be found in the build log:' full_$SUFFIX.log | tail -n1 | sed -s 's/build\.log.*/build.log/' )" > build_$SUFFIX.log || die 

    # Create info log
    echo "System:"  >> info_$SUFFIX.log
    echo "$(vagrant --version)" >> info_$SUFFIX.log
    echo "$OS" >> info_$SUFFIX.log
    echo "$(vagrant ssh -c 'uname -a')" >> info_$SUFFIX.log
    echo "" >> info_$SUFFIX.log
    echo "Steps to reproduce the bug:" >> info_$SUFFIX.log
    echo "Run the bootstrap-prefix.sh" >> info_$SUFFIX.log

    #vagrant destroy
    ./report.sh $OS full_$SUFFIX.log build_$SUFFIX.log info_$SUFFIX.log $KEY
    exit 1
else
    echo "Success to build prefix"
    #vagrant destroy
    exit 0
fi
