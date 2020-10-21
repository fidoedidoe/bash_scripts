#!/bin/bash

# Written by FidoeDidoe, 1st July 2020
# For updates, refer to: https://github.com/fidoedidoe/bash_scripts/blob/master/apt-update-plus-cleanup.sh
#
#
# For more info execute ./<script> --help


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
EXIT_PROMPT="N"
APT_CLEAN="N"
NO_PROMPT=""
SKIP_PROCESS_CHECK="N"

# function(s)
#############

function parse_parameters() {

   while [[ ${#} -ge 1 ]]; do
       case "${1}" in
           # OPTIONAL FLAGS
           "-d"|"--dist-upgrade") DIST_UPGRADE="Y";;
           "-e"|"--exit-prompt" ) EXIT_PROMPT="Y" ;;
           "-a"|"--apt-clean" ) APT_CLEAN="Y" ;;
           "-n"|"--no-prompt" ) NO_PROMPT="--assume-yes" ;;
           "-s"|"--skip-process-check" ) SKIP_PROCESS_CHECK="Y" ;;

           # HELP!
           "-h"|"--help") help_menu; exitPrompt; exit ;;
       esac
       shift
    done
}

function help_menu() {

# For updates, refer to: https://github.com/fidoedidoe/bash_scripts/blob/master/apt-update-plus-cleanup.sh
echoMsg "=====\nOVERVIEW: Updates apt repos, checks for: apt; snap; flatpack updates\n" "GREEN"
echoMsg "USAGE:    $(basename "$0") <options>" "GREEN"
echoMsg "EXAMPLE:  $(basename "$0") --dist-upgrade --exit-prompt" "GREEN"
echoMsg "EXAMPLE:  $(basename "$0") -e" "GREEN"
echoMsg "EXAMPLE:  $(basename "$0") --skip-process-check" "GREEN"
echoMsg "EXAMPLE:  $(basename "$0") --help" "GREEN"
echoMsg "EXAMPLE:  $(basename "$0")\n" "GREEN"
echoMsg "OPTIONAL PARAMETERS:" "GREEN"
echoMsg "  -d | --dist-upgrade:       Run 'apt dist-upgrade', when omitted runs 'apt upgrade'" "GREEN"
echoMsg "  -e | --exit-prompt:        Prompt for key press to exit script.\n                             NOTE: Useful when executed from desktop icon rather than bash terminal." "GREEN"
echoMsg "  -a | --apt-clean:          Run apt auto-clean + auto-remove after installing apt updates.\n                             NOTE: obsolete packages are always removed *before* running apt update" "GREEN"
echoMsg "  -n | --no-prompt:          Do not prompt user (no need for interactive shell)" "GREEN"
echoMsg "  -s | --skip-process-check: Skip initial running process check" "GREEN"
echoMsg "  -s | --help:               Show Help" "GREEN"
echoMsg "=====\n" "GREEN"
}

function start_msg() {

   echoMsg "======\nScript: starting...\n======\n\n" "GREEN"
   echoMsg "======\nPassed Parameters/operation:" "GREEN"
   case "$DIST_UPGRADE" in
      "Y" ) echoMsg " -d | --dist-upgrade: Script will run 'apt-get dist-upgrade" "GREEN";;
      "N" ) echoMsg " -d | --dist-upgrade: NOT specified, defaulting to run 'apt-get upgrade'" "GREEN";;
   esac
   case "$EXIT_PROMPT" in
      "Y" ) echoMsg " -e | --exit-prompt:  Script will prompt for key press to exit" "GREEN";;
      "N" ) echoMsg " -e | --exit-prompt:  NOT specified, defaulting to exit on completion" "GREEN";;
   esac
   case "$APT_CLEAN" in
      "Y" ) echoMsg " -a | --apt-clean: Script will run 'apt-get autoremove & autoclean' after installing new packages" "GREEN";;
      "N" ) echoMsg " -a | --apt-clean: NOT specified, obsolete packages will remain after install" "GREEN";;
   esac
   case "$NO_PROMPT" in
      "--assume-yes" ) echoMsg " -n | --no-prompt: Script will run 'apt-get $NO_PROMPT' to mitigate need for interactive shell" "GREEN";;
                   * ) echoMsg " -n | --no-prompt: NOT specified, if needed user input required via shell" "GREEN";;
   esac
   case "$SKIP_PROCESS_CHECK" in
      "Y" ) echoMsg " -s | --skip-process-check: Skip initial 'running process' check" "GREEN";;
      "N" ) echoMsg " -s | --skip-process-check: NOT specified, intial 'running process' check will be invoked" "GREEN";;
   esac
   echoMsg "======\n" "GREEN"
}

function echoMsg() {

  COLOUR_RED="\033[0;31m"
  COLOUR_GREEN="\033[1;32m"
  COLOUR_YELLOW="\033[1;33m"
  COLOUR_NEUTRAL="\033[0m"

  # shellcheck disable=SC2034
  MSG=${1:-}

  # shellcheck disable=SC2034
  COLOUR=${2:-}

  case "$COLOUR" in
     "NEUTRAL"     ) COLOUR=$COLOUR_NEUTRAL;;
       "GREEN"     ) COLOUR=$COLOUR_GREEN;;
         "RED"     ) COLOUR=$COLOUR_RED;;
         "YELLOW"|*) COLOUR=$COLOUR_YELLOW;;
  esac  

  # shellcheck disable=SC2034
  ECHO_ARG1=${3:-}

  # shellcheck disable=SC2086
  echo -e ${ECHO_ARG1} "${COLOUR}${MSG}${COLOUR_NEUTRAL}"
}

function exitPrompt() {

   case "$EXIT_PROMPT" in
      "Y" ) echoMsg "===============\nPress any key to close this script $SUDO_USER.\n===============\n" "YELLOW" -n
            read -n 1 -s -r -p "";;
      "N" ) echoMsg "";;
   esac
}


function checkRunningProcesses () {

   SHELL_SCRIPT_NAME=$(basename "$0")
   PROCESS_LIST="apt|dpkg|aptitude|synaptic|gpgv"
   PROCESS_COUNT="1"
   # shellcheck disable=SC2009
   # shellcheck disable=SC2126
   PROCESS_COUNT=$( ps aux | grep -i -E "$PROCESS_LIST" | grep -v "$SHELL_SCRIPT_NAME" | grep -v grep | wc -l || true)
   # shellcheck disable=SC2009
   if [[ "$PROCESS_COUNT" -ne "0" ]]; then
      #ps aux | grep -i -E "$PROCESS_LIST" | grep -v $SHELL_SCRIPT_NAME | grep -v grep
      echoMsg "Warning. $PROCESS_COUNT conflicting processes found" "RED"
      #ps aux | grep root
      return 1
   else
      return 0 
   fi
}

function updatePackageRepo () {

   ERROR="0"
   echoMsg "===\napt: refreshing $UBUNTU_VERSION repositories...\n==="
   apt-get $NO_PROMPT update || ERROR="1"
   if [[ $ERROR -eq "1" ]]; then
      #echoMsg "ERROR: $ERROR" "RED"
      return 1
   else
      #echoMsg "ERROR: $ERROR"
      return 0
   fi
}

function updatePackages () {

   ERROR="0"
   case "$DIST_UPGRADE" in
        "Y"|"y" ) echoMsg "===\napt: checking for updates in refreshed repositories using: 'apt dist-upgrade'\n==="
                  #apt-get $NO_PROMPT dist-upgrade  || ERROR="1";;
                  apt-get $NO_PROMPT -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade || ERROR="1";;
        "N"|"n" ) echoMsg "===\napt: checking for updates in refreshed repositories using: 'apt upgrade'\n==="
                  #apt-get $NO_PROMPT upgrade || ERROR="1";;
                  apt-get $NO_PROMPT -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade || ERROR="1";;
   esac
   if [[ $ERROR -eq "1" ]]; then
      #echoMsg "ERROR: $ERROR" "RED"
      return 1
   else
      #echoMsg "ERROR: $ERROR"
      return 0
   fi
}

function packageCleanup () {

   #if [[ $APT_CLEAN = "Y" ]]; then
      ERROR="0"
      echoMsg "===\napt: removing obsolescence...\n==="
      apt-get $NO_PROMPT autoremove || ERROR="1"
      if [[ $ERROR -eq "1" ]]; then
         #echoMsg "ERROR: $ERROR" "RED"
         return 1
      else
         apt-get $NO_PROMPT autoclean || ERROR="1"
         if [[ $ERROR -eq "1" ]]; then
            #echoMsg "ERROR: $ERROR"
            return 1
         else
            return 0
         fi
      fi
  #else
  #   return 0
  #fi	  
}

#-----------------
##################
# Start of script
##################
#-----------------

parse_parameters "${@}"
start_msg

# Check for root
################
if [[ "$EUID" -ne 0 ]]; then 
   echoMsg "==========================\napt-update-plus-cleanup.sh: Please run as root\n==========================" "RED"
   exitPrompt
   exit
fi


# Update apt repos, get new packages and clean up
#################################################

# Checking if apt / synaptics like processes are running
# ------------------------------------------------------
if [[ $SKIP_PROCESS_CHECK != "Y" ]]; then
  echoMsg "===\napt: checking it's safe to run updates...\n==="
  until checkRunningProcesses; do
     echoMsg "Retrying in 5 seconds (<CTRL> + C to terminate)...."
     sleep 5
  done
fi  

# apt cleanup
#------------
until packageCleanup; do
   echoMsg "Warning. Another package manager is running." "RED"
   echoMsg "Retrying in 5 seconds (<CTRL> + C to terminate)...."
   sleep 5
done

# Update apt repos
#-----------------
until updatePackageRepo; do
   echoMsg "Warning. Another package manager is running." "RED"
   echoMsg "Retrying in 5 seconds (<CTRL> + C to terminate)...."
   sleep 5
done

# Update apt packages
#--------------------
until updatePackages; do
   echoMsg "Warning. Another package manager is running." "RED"
   echoMsg "Retrying in 5 seconds (<CTRL> + C to terminate)...."
   sleep 5
done

# apt cleanup
#------------

if [[ $APT_CLEAN = "Y" ]]; then
   until packageCleanup; do
      echoMsg "Warning. Another package manager is running." "RED"
      echoMsg "Retrying in 5 seconds (<CTRL> + C to terminate)...."
      sleep 5
   done
fi 

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
         if [[ $NO_PROMPT = "" ]]; then
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
         else
            snap refresh
         fi 
      fi
      # snaps are updated on a schedule (4 times per day). Due to this, 
      # we may find "disabled" snaps (older revisions) that have been updated outside of this script/conditional code block above.  
      # To mitigate having too many old revisions hanging around "always check for and remove outdated revisions" (rather than having within the above conditional code block). 
      echoMsg "==========\nsnap store: removing obsolescence...\n=========="
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

echoMsg "===============\nScript complete! $UBUNTU_VERSION is now up to date :)\n===============" "GREEN"
exitPrompt
