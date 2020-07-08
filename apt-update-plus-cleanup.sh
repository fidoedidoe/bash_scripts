#!/bin/bash
# Runs: 
#  apt update
#  apt auto remove/clean
#  removes disabled snap apps

# instruct bash to: 
#  -e "fail on non zero exit status"
#  -u "fail on non-defined variables"
#  -o pipefail "prevent errors in pipeline from being masked"

set -euo pipefail

# Check for root
if [ "$EUID" -ne 0 ]
  then echo "apt-update-plus-cleanup.sh: Please run as root"
  exit
fi

echo "==="
echo "apt: updating repositories..."
echo "==="
apt update
echo "==="
echo "apt: checking for updates..."
echo "==="
apt dist-upgrade
echo "==="
echo "apt: cleaning up..."
echo "==="
apt autoremove && apt autoclean
echo "==="
echo "apt: complete!"
echo "==="
echo ""
echo ""
echo "=========="
echo "snap store: checking for updates..."
echo "=========="
snap refresh
echo "=========="
echo "snap store: listing apps..."
echo "=========="
snap list --all

echo ""
echo ""
LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
       echo -n "removing $snapname: rev - $revision....." && snap remove "$snapname" --revision="$revision"
    done
echo "Bodhi is now up to date!"
read -p "Press [Enter] to close this window $SUDO_USER."
