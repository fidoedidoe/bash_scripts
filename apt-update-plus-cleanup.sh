#!/bin/bash
# Runs: 
#  apt update
#  apt auto remove/clean
#  updates snap apps
#  updates flatpak apps

# instruct bash to: 
#  -e "fail on non zero exit status"
#  -u "fail on non-defined variables"
#  -o pipefail "prevent errors in pipeline from being masked"

set -euo pipefail

# variables: 
SNAP=/usr/bin/snap
FLATPAK=/usr/bin/flatpak
UBUNTU_VERSION=$(lsb_release -ds)

# Check for root
if [ "$EUID" -ne 0 ]
  then echo "apt-update-plus-cleanup.sh: Please run as root"
  exit
fi

echo "==="
echo "apt: updating $UBUNTU_VERSION repositories..."
echo "==="
apt update
echo "==="
echo "apt: checking for $UBUNTU_VERSION updates..."
echo "==="
apt dist-upgrade
echo "==="
echo "apt: remove obsolete dependancies for $UBUNTU_VERSION..."
echo "==="
apt autoremove && apt autoclean
echo "==="
echo "apt: $UBUNTU_VERSION updates complete!"
echo "==="
echo ""
echo ""

#is snap installed?
if [ -f "$SNAP" ]; then
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
else
   echo "====="
   echo "snapd: not installed, skipping..."
   echo "====="
fi

#is flatpak installed?
if [ -f "$FLATPAK" ]; then
   echo "======="
   echo "flatpak: checking for updates..."
   echo "======="
   flatpak update
   echo "======="
   echo "flatpak: listing apps..."
   echo "======="
   flatpak list
   echo ""
   echo ""
else
   echo "====="
   echo "flatpak: not installed, skipping..."
   echo "====="
fi

echo ""
echo ""

echo "$UBUNTU_VERSION is now up to date!"
read -p "Press [Enter] to close this window $SUDO_USER."
