#!/bin/bash

# Written by FidoeDidoe, 1st July 2020
# For updates, refer to: https://github.com/fidoedidoe/bash_scripts/blob/master/apt-update-plus-cleanup.sh

# Usage: 
# sudo ./apt-update-plus-cleanup.sh <param1> [optional]
#   param1 (optional): Switch to control whether to run 'apt dist-upgrade' or 'apt upgrade' 
#                      Possible values [Y|y|N|n]
#                      Default: N
#                      Y|y: Instructs script to run "apt dist-upgrade"
#                      N|n: (or not present): Instructs script to run "apt upgrade" 
#   param2 (optional): Prompt to exit script when complete which is useful when executed via icon from desktop (rather than terminal) 
#                      Possible values [Y|y|N|n]
#                      Default: N
#                      Y|y: Promots to "press any key to exit"
#                      N|n: Exits script without prompting 

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

# function(s)
#############
echoMsg() {

  # shellcheck disable=SC2034
  YELLOW='\033[1;33m'

  # shellcheck disable=SC2034
  NC='\033[0m' # No Color
 
  # shellcheck disable=SC2034
  MSG=${1:-}

  # shellcheck disable=SC2034
  COLOUR=${2:-}

  case "$COLOUR" in
     "NOCOLOUR"    ) COLOUR=${NC};;
       "GREEN"     ) COLOUR='\033[1;32m';;
         "RED"     ) COLOUR='\033[1;33m';;
         "YELLOW"|*) COLOUR='\033[1;33m';;
  esac  

  # shellcheck disable=SC2034
  ARG1=${3:-}

  # shellcheck disable=SC2086
  echo -e ${ARG1} "${COLOUR}${MSG}${NC}"
}

exitPrompt() {
case "$EXIT_PROMPT" in
   "Y"|"y" ) echoMsg "Press any key to close this script $SUDO_USER.\n===============\n" "YELLOW" -n
             read -n 1 -s -r -p "";;
   "N"|"n" ) echoMsg "===============\n";;
esac
}

# Check for root
################
if [[ "$EUID" -ne 0 ]]; then 
   echoMsg "==========================\napt-update-plus-cleanup.sh: Please run as root\n=========================="
   exitPrompt
   exit
fi

# check command line input arguments
####################################
if [[ -n "${1-N}" ]]; then
   DIST_UPGRADE="${1-N}"
   if [[ "$DIST_UPGRADE" =~ ^(N|n|Y|y)$ ]]; then
      echo ""
   else
      echoMsg "========\n<param1>: '$DIST_UPGRADE' is not in the expacted format [Y|N] cannot coniinue\n========"
      exitPrompt
      exit
   fi 
fi

if [[ -n "${2-Y}" ]]; then
   EXIT_PROMPT="${2-Y}"
   if [[ "$EXIT_PROMPT" =~ ^(N|n|Y|y)$ ]]; then
      echo ""
   else
      echoMsg "========\n<param1>: '$EXIT_PROMPT' is not in the expacted format [Y|N] cannot coniinue\n========"
      exitPrompt
      exit
   fi 
fi

echoMsg "======\nScript: starting...\n======\n"


# Checking is apt can be run / is locked
########################################

#LOCKED=$(lsof /var/lib/dpkg/lock >> /dev/null 2>&1)
#if [ LOCKED = "Y" ]; then
#   echoMag "LOCKED: $LOCKED"
#   exit 1
#fi


# Update apt repos and run update / dist-update
###############################################

echoMsg "===\napt: refreshing $UBUNTU_VERSION repositories...\n==="
apt update
case "$DIST_UPGRADE" in
     "Y"|"y" ) echoMsg "===\napt: checking for updates in refreshed repositories using: 'apt dist-upgrade'\n==="
               apt dist-upgrade;;
     "N"|"n" ) echoMsg "===\napt: checking for updates in refreshed repositories using: 'apt upgrade'\n==="
               apt upgrade;;
esac
echoMsg "===\napt: removing obsolescence...\n==="
apt autoremove && apt autoclean
echoMsg "===\napt: finished!\n===\n\n"

# Check for snapd/snap and update snap apps
###########################################

if [[ "$PID1_PROC" == "systemd" ]]; then
   if [ -f "$SNAP" ]; then
      echoMsg "==========\nsnap store: listing all snap apps...\n=========="
      snap list --all --color auto
      echoMsg "\n==========\nsnap store: listing snaps with pending updates...\n=========="
      SNAP_LIST=$(LANG=en_US.UTF-8 snap refresh --list 2>&1)
      echo "${SNAP_LIST}"
      if [[ $SNAP_LIST != "All snaps up to date." ]]; then
         echoMsg "==========\nsnap store: Update snap apps? [Y/n]...\n==========\n"
         PROMPT=""
         read -r -p "" -e -n 1 PROMPT
         if [ -z "$PROMPT" ]; then
             PROMPT="Y"
         fi
         if [[ $PROMPT =~ ^[Yy]$ ]]; then
            echoMsg "==========\nsnap store: updatings snaps...\n=========="
            snap refresh
         else
            echoMsg "==========\nsnap store: $SUDO_USER, you entered '$PROMPT', skipping check for snap updates ...\n==========\n\n"
         fi
      fi
      # snaps are updated on a schedule (4 times per day). Due to this, 
      # we may find "disabled" snaps (older revisions) that have been updated outside of this script/conditional code block above.  
      # To mitigate having too many old revisions hanging around "always check for and remove outdated revisions" (rather than having within the above conditional code block). 
      LANG=en_US.UTF-8 snap list --all --color auto | awk '/disabled/{print $1, $3}' |
         while read -r snapname revision; do
            echoMsg "removing $snapname: rev - $revision....." -n && snap remove "$snapname" --revision="$revision"
         done
      echoMsg "==========\nsnap store: finished!\n=========="
   else
      echoMsg "=====\nsnapd: is not installed, skipping...\n====="
   fi
else
      echoMsg "=======\nsystemd: is not running (you're using 'init'), snapd wont be running normally, skipping...\n======="
fi
echoMsg "\n\n"

# Check for flatpak and update flatpak apps
###########################################

if [ -f "$FLATPAK" ]; then
   echoMsg "=======\nflatpak: listing apps...\n======="
   flatpak list
   echoMsg "=======\nflatpak: checking for updates...\n======="
   flatpak update
   echoMsg "=======\nflatpak: finished!\n======="
else
   echoMsg "=======\nflatpak: is not installed, skipping...\n======="
fi
echoMsg "\n\n"

echoMsg "===============\nScript complete! $UBUNTU_VERSION is now up to date :)"
exitPrompt
