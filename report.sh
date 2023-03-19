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
TITLE="$TITLE: $STABLE bootstrap-prefix.sh fails"

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
$BUGZ search "$TITLE" -r "alexander@neuwirth-informatik.de" | tee bgo.out
echo "Failed: $TITLE"
TITLEBUG=$( grep -c "$TITLE" bgo.out )
if [ $TITLEBUG -ge 1 ] ; then
  echo "found"
else
  echo "not found"
fi
# We count with -c instead of -Fq due to cygwin...
NOBUG=$( grep -c "Info: No bugs" bgo.out )
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
        | tee bgo.out

    id=$(grep "Info: Bug .* submitted" bgo.out | sed 's/[^0-9]//g')
    # Attach the logs
    $BUGZ attach --content-type "application/x-bzip2" --description "" $id $FULL | tee bgo.out 
    $BUGZ attach --content-type "application/x-bzip2" --description "" $id $BUILD | tee bgo.out 
else
    echo "Bug exists"
    #exit 1
    # abort if multiple bugs reported
    ONEBUG=$( grep -c "Info: 1 bug" bgo.out)
    if [ $ONEBUG -ge 1 ]
    then
        # get bug id
        id=$(cat bgo.out | tail -n2 | head -n1 | awk '{print $1}')
        echo "Bug id: $id"
        $BUGZ get "$id" | tee bgo.out
        OSBUG=$(grep -c "$OS" bgo.out)
        if [ $OSBUG -ge 1 ]
        then
            # already reportet for this OS
            echo "Bug already reported for $OS"
        else
            echo "Adding message for $OS"
            # add message fails for this os as well
            $BUGZ modify --comment-from "$INFO" $id | tee bgo.out 
            # attach logs
            $BUGZ attach --content-type "application/x-bzip2" --description "" $id $FULL | tee bgo.out
            $BUGZ attach --content-type "application/x-bzip2" --description "" $id $BUILD | tee bgo.out
        fi
    else
        echo "Multiple bugs found, aborting"
    fi
fi

