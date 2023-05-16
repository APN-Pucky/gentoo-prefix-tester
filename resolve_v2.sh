#!/bin/bash
if [ ! $# -eq 5 ]
then
    echo "Usage: $0 OS STABLE INFO_LOG KEY STAGE"
    exit 1
else
    OS=$1
    STABLE=$2
    KEY=$3
    INFO=$4
    STAGE=$5
fi

TITLE="bootstrap-prefix.sh $STAGE fails"


# with explicit connection name to avoid missing default config error
BUGZ="bugz --key $KEY --config-file gentoo.conf --connection Gentoo"

###################
# Resolve the bug #
###################


# Search for existing bugs
$BUGZ search "$TITLE" -r "alexander@neuwirth-informatik.de" | tee bgo.out
echo "Failed: $TITLE"
TITLEBUG=$( grep -c "$TITLE" bgo.out )
if [ $TITLEBUG -ge 1 ] ; then
  echo "found"
else
  echo "not found"
fi
# We count with -c instead of -Fq due to cygwin... -> turned out to be a bug pybugz with windwos/cygwin
NOBUG=$( grep -c "Info: No bugs" bgo.out )
if [ $NOBUG -ge 1 ] ; then
    echo "There is no bug to resolve"
else
    ids=$(cat bgo.out | awk '$1 ~ /^[0-9]+$/ {print $1}')
    echo "Found bugs: $ids"
    for id in $ids
    do
        echo "Checking bug $id"
        $BUGZ get "$id" | tee bgo.out
        OSBUG=$(grep -c "$OS $STABLE prefix" bgo.out)
        if [ $OSBUG -ge 1 ]
        then
            OSBUG=$(grep -c "resolved for $OS $STABLE prefix" bgo.out)
            if [ $OSBUG -ge 1 ]
            then
                echo "Bug $id is already resolved for $OS $STABLE prefix"
            else
                echo "Found bug $id for $OS $STABLE prefix"
                $BUGZ modify --comment-from "$INFO" $id | tee bgo.out 
            fi
        else
            echo "Bug $id is not for $OS $STABLE prefix"
        fi
    done
fi

