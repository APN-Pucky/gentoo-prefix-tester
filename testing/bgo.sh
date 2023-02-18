#!/bin/bash
#
TITLE=$(grep -i -A 1 "Details might be found in the build log:" full.log | tail -n1  | sed 's/.*portage\/\(.*\)\/temp.*/\1/')
bugz post \
    --product "Gentoo/Alt"          \
    -a prefix@gentoo.org \
    --component "Prefix Support"    \
    --version "unspecified"           \
    --title "$TITLE: bootstrap.sh fails"          \
    --op-sys "Linux"                  \
    --platform "All"                  \
    --priority "Normal"               \
    --severity "Normal"            \
    --alias ""                        \
    --description-from "./info.log"   \
    --batch                           \
    --default-confirm n               \
    --cc alexander@neuwirth-informatik.de \
    1>bgo.sh.out 2>bgo.sh.err

id=$(grep "Info: Bug .* submitted" bgo.sh.out | sed 's/[^0-9]//g')

bugz attach --content-type "text/plain" --description "" $id full.log 1>bgo.sh.out 2>bgo.sh.err 
bugz attach --content-type "text/plain" --description "" $id build.log 1>bgo.sh.out 2>bgo.sh.err 
