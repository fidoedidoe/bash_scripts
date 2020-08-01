#!/bin/bash

# Written by FidoeDidoe, 1st July 2020
# For updates, refer to: https://github.com/fidoedidoe/bash_scripts/blob/master/apt-update-plus-cleanup.sh

# Usage: 
# sudo ./apt-update-plus-cleanup.sh <param1> [optional]
#   param1 (optional): Possible values [Y|y|N|n]
#                      Default: N
#                      Y|y: Instructs script to run "apt dist-upgrade"
#                      N|n (or not present): Instructs script to run "apt upgrade" 

# Runs: 
# ----
#  apt update
#  apt auto remove/clean
#  updates snap apps
#  updates flatpak apps

# instruct bash to:
# ----------------
#  -e "fail on non zero exit status"
#  -u "fail on non-defined variables"
#  -o pipefail "prevent errors in pipeline from being masked"

set -euo pipefail

# variables: 
SNAP=/usr/bin/snap
FLATPAK=/usr/bin/flatpak
UBUNTU_VERSION=$(lsb_release -ds)
DIST_UPGRADE="N"
PID1_PROC=$(ps --no-headers -o comm 1) #Checks whether systemd or init is running

# functions
echoMsg() {

  # shellcheck disable=SC2034
  YELLOW='\033[1;33m'

  # shellcheck disable=SC2034
  NC='\033[0m' # No Color
 
  # shellcheck disable=SC2034
  MSG=${1:-}

  # shellcheck disable=SC2034
  ARG1=${2:-}

  eval 'echo -e $ARG1 $YELLOW$MSG$NC'
}

# Check for root
if [[ "$EUID" -ne 0 ]]; then 
   echoMsg "=========================="
   echoMsg "apt-update-plus-cleanup.sh: Please run as root"
   echoMsg "=========================="
   exit
fi

# check command line arguments
if [[ -n "${1-N}" ]]; then
   DIST_UPGRADE="${1-N}"
   if [[ "$DIST_UPGRADE" =~ ^(N|n|Y|y)$ ]]; then
      echo ""
   else
      echoMsg "========"
      echoMsg "<param1> $DIST_UPGRADE is not in the expacted format [Y|N] cannot coniinue"
      echoMsg "========"
      exit
   fi 
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
case "$DIST_UPGRADE" in
     "Y"|"y" ) echoMsg "apt: checking for updates in refreshed repositories using: 'apt dist-upgrade'"
               echoMsg "==="
               apt dist-upgrade;;
     "N"|"n" ) echoMsg "apt: checking for updates in refreshed repositories using: 'apt upgrade'"
               echoMsg "==="
               apt upgrade;;
esac
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

if [[ "$PID1_PROC" == "systemd" ]]; then
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
          while read -r snapname revision; do
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
else
      echoMsg "======="
      echoMsg "systemd: is not running (you're using 'init'), snapd wont be running normally, skipping..."
      echoMsg "======="
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
echoMsg "Script complete! $UBUNTU_VERSION is now up to date :) Press anykey to close this script $SUDO_USER."
echoMsg "===============" -n
read -n 1 -s -r -p ""
