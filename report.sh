if [ ! $# -eq 3 ]
then
    echo "Usage: $0 Vagrantfile"
    exit 1
else
    OS=$1
    FULL=$2
    BUILD=$3
    INFO=$4
fi

TITLE=$(grep -i -A 1 "Details might be found in the build log:" $FULL.log | tail -n1  | sed 's/.*portage\/\(.*\)\/temp.*/\1/')
TITLE="$TITLE: bootstrap-prefix.sh fails"
# compress both logs with bz2
bzip2 -z $FULL
bzip2 -z $BUILD
FULL=$FULL.bz2
BUILD=$BUILD.bz2

##################
# Report the bug #
##################


# Search for existing bugs
bugz search "$TITLE" -r alexander@neuwirth-informatik.de 1> bgo_$SUFFIX.out 2> bgo_$SUFFIX.err
if grep -Fxq "$TITLE" bgo_$SUFFIX.out
then
    # get bug id
    id=$(grep "$TITLE" bgo_$SUFFIX.out | tail -n1 | awk '{print $1}')
    bugz get $id 1> bgo_$SUFFIX.out 2> bgo_$SUFFIX.err
    if grep -Fxq "$OS" bgo_$SUFFIX.out
    then
        # already reportet for this OS
        echo "Bug already reported for $OS"
    else
        # add message fails for this os as well
        bugz modify --comment "fails for $OS as well" $id 1>bgo_$SUFFIX.out 2>bgo_$SUFFIX.err
        # attach logs
        bugz attach --content-type "text/plain" --description "" $id $FULL 1>bgo_$SUFFIX.out 2>bgo_$SUFFIX.err
        bugz attach --content-type "text/plain" --description "" $id $BUILD 1>bgo_$SUFFIX.out 2>bgo_$SUFFIX.err
    fi
else
    # Post the bug
    bugz post \
        --product "Gentoo/Alt"          \
        -a prefix@gentoo.org \
        --component "Prefix Support"    \
        --version "unspecified"           \
        --title "$TITLE"          \
        --op-sys "Linux"                  \
        --platform "All"                  \
        --priority "Normal"               \
        --severity "Normal"            \
        --alias ""                        \
        --description-from "./$INFO"   \
        --batch                           \
        --default-confirm n               \
        --cc alexander@neuwirth-informatik.de \
        1>bgo_$SUFFIX.out 2>bgo_$SUFFIX.err 

    id=$(grep "Info: Bug .* submitted" bgo_$SUFFIX.out | sed 's/[^0-9]//g')
    # Attach the logs
    bugz attach --content-type "text/plain" --description "" $id $FULL 1>bgo_$SUFFIX.out 2>bgo_$SUFFIX.err 
    bugz attach --content-type "text/plain" --description "" $id $BUILD 1>bgo_$SUFFIX.out 2>bgo_$SUFFIX.err 
fi

