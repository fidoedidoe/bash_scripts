#!/bin/bash
# Removes old revisions of snaps
# CLOSE ALL SNAPS BEFORE RUNNING THIS

# instruct bash to: 
#  -e "fail on non zero exit status"
#  -u "fail on non-defined variables"
#  -o pipefail "prevent errors in pipeline from being masked"
set -euo pipefail

# Check for root
if [ "$EUID" -ne 0 ]
  then echo "snap-remove-disabled.sh: Please run as root"
  exit
fi

snap list --all

echo ""
echo ""
LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
       echo -n "removing $snapname: rev - $revision....." && snap remove "$snapname" --revision="$revision"
    done
