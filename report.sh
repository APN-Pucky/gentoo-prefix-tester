if [ ! $# -eq 6 ]
then
    echo "Usage: $0 OS STABLE FULL_LOG BUILD_LOG INFO_LOG KEY"
    exit 1
else
    OS=$1
    STABLE=$2
    FULL=$3
    BUILD=$4
    INFO=$5
    KEY=$6
    if [ ! -f "$FULL" ]; then
      echo "$FULL does not exist."
      exit 1
    fi
    if [ ! -f "$BUILD" ]; then
      echo "$BUILD does not exist."
      exit 1
    fi
    if [ ! -f "$INFO" ]; then
      echo "$INFO does not exist."
      exit 1
    fi
fi

TITLE=$(grep -i -A 1 "Details might be found in the build log:" $FULL | tail -n1  | sed 's/.*portage\/\(.*\)\/temp.*/\1/')$(grep -i -A 1 "I tried running" $FULL | tail -n1 )
TITLE="$TITLE: bootstrap-prefix.sh fails"

# compress both logs with bz2
bzip2 -z $FULL
bzip2 -z $BUILD
FULL=$FULL.bz2
BUILD=$BUILD.bz2

# with explicit connection name to avoid missing default config error
BUGZ="bugz --key $KEY --config-file gentoo.conf --connection Gentoo"

##################
# Report the bug #
##################


# Search for existing bugs
$BUGZ search "$TITLE" -r alexander@neuwirth-informatik.de 1> bgo_${SUFFIX}.out 2> bgo_${SUFFIX}.err
echo "Failed: $TITLE"
if grep -Fq "$TITLE" bgo_${SUFFIX}.out ; then
  echo "found"
else
  echo "not found"
fi
NOBUG=$( grep -c "Info: No bugs" bgo_${SUFFIX}.out )
if [ $NOBUG -ge 1 ] ; then
    echo "Reporting the bug"
    # Post the bug
    $BUGZ post \
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
        --description-from "$INFO"   \
        --batch                           \
        --default-confirm n               \
        --cc alexander@neuwirth-informatik.de \
        1>bgo_${SUFFIX}.out 2>bgo_${SUFFIX}.err 

    id=$(grep "Info: Bug .* submitted" bgo_${SUFFIX}.out | sed 's/[^0-9]//g')
    # Attach the logs
    $BUGZ attach --content-type "application/x-bzip2" --description "" $id $FULL 1>bgo_${SUFFIX}.out 2>bgo_${SUFFIX}.err 
    $BUGZ attach --content-type "application/x-bzip2" --description "" $id $BUILD 1>bgo_${SUFFIX}.out 2>bgo_${SUFFIX}.err 
else
    echo "Bug exists"
    #exit 1
    # abort if multiple bugs reported
    ONEBUG=$( grep -c "Info: 1 bug" bgo_${SUFFIX}.out)
    if [ $ONEBUG -ge 1 ]
    then
        # get bug id
        id=$(cat bgo_${SUFFIX}.out | tail -n2 | head -n1 | awk '{print $1}')
        echo "Bug id: $id"
        $BUGZ get "$id" 1> bgo_${SUFFIX}.out 2> bgo_${SUFFIX}.err
        OSBUG=$(grep -c "$OS" bgo_${SUFFIX}.out)
        if [ $OSBUG -ge 1 ]
        then
            # already reportet for this OS
            echo "Bug already reported for $OS"
        else
            echo "Adding message for $OS"
            # add message fails for this os as well
            $BUGZ modify --comment-from "$INFO" $id 1>bgo_${SUFFIX}.out 2>bgo_${SUFFIX}.err
            # attach logs
            $BUGZ attach --content-type "application/x-bzip2" --description "" $id $FULL 1>bgo_${SUFFIX}.out 2>bgo_${SUFFIX}.err
            $BUGZ attach --content-type "application/x-bzip2" --description "" $id $BUILD 1>bgo_${SUFFIX}.out 2>bgo_${SUFFIX}.err
        fi
    else
        echo "Multiple bugs found, aborting"
    fi
fi

