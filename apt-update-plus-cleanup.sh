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

# functions
echoMsg() {

  YELLOW='\033[1;33m'
  NC='\033[0m' # No Color
 
  MSG=${1:-}
  ARG1=${2:-}

  eval 'echo -e $ARG1 $YELLOW$MSG$NC'
}

# Check for root
if [ "$EUID" -ne 0 ]; then 
   echoMsg "=========================="
   echoMsg "apt-update-plus-cleanup.sh: Please run as root"
   echoMsg "=========================="
   exit
fi

echoMsg "======"
echoMsg "Script: starting..."
echoMsg "======"
echoMsg ""

echoMsg "==="
echoMsg "apt: refreshing $UBUNTU_VERSION repositories..."
echoMsg "==="
apt update
echoMsg "==="
echoMsg "apt: checking for updates in refreshed repositories..."
echoMsg "==="
apt dist-upgrade
echoMsg "==="
echoMsg "apt: removing obsolescence..."
echoMsg "==="
apt autoremove && apt autoclean
echoMsg "==="
echoMsg "apt: finished!"
echoMsg "==="
echo ""
echo ""

#is snap installed?
if [ -f "$SNAP" ]; then
   echoMsg "=========="
   echoMsg "snap store: checking for updates..."
   echoMsg "=========="
   snap refresh
   echoMsg "=========="
   echoMsg "snap store: listing apps..."
   echoMsg "=========="
   snap list --all
   echo ""
   echo ""
   LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
       while read snapname revision; do
          echoMsg "removing $snapname: rev - $revision....." -n && snap remove "$snapname" --revision="$revision"
       done
   echoMsg "=========="
   echoMsg "snap store: finished!"
   echoMsg "=========="

else
   echoMsg "====="
   echoMsg "snapd: is not installed, skipping..."
   echoMsg "====="
fi
echo ""
echo ""

#is flatpak installed?
if [ -f "$FLATPAK" ]; then
   echoMsg "======="
   echoMsg "flatpak: checking for updates..."
   echoMsg "======="
   flatpak update
   echoMsg "======="
   echoMsg "flatpak: listing apps..."
   echoMsg "======="
   flatpak list
   echoMsg "======="
   echoMsg "flatpak: finished!"
   echoMsg "======="
else
   echoMsg "======="
   echoMsg "flatpak: is not installed, skipping..."
   echoMsg "======="
fi

echo ""
echo ""

echoMsg "==============="
echoMsg "Script complete! $UBUNTU_VERSION is now up to date :) Press [Enter] to close this window $SUDO_USER."
echoMsg "===============" -n
read -p ""
