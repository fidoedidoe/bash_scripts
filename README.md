# bash_scripts
miscellaneous bash scripts

## apt-update-plus-cleanup.sh

OVERVIEW: Updates apt repos, checks for: apt; snap; flatpack updates

* USAGE:    apt-update-plus-cleanup.sh <options>
* EXAMPLE:  apt-update-plus-cleanup.sh --dist-upgrade --exit-prompt --apt-cleanup
* EXAMPLE:  apt-update-plus-cleanup.sh --dist-upgrade --exit-prompt
* EXAMPLE:  apt-update-plus-cleanup.sh -e
* EXAMPLE:  apt-update-plus-cleanup.sh --help
* EXAMPLE:  apt-update-plus-cleanup.sh

OPTIONAL PARAMETERS:
*   -d | --dist-upgrade: Run 'apt dist-upgrade', when omitted runs 'apt upgrade'
*   -a | --apt-cleanup:  Clean up old packages immediately after update.
         NOTE: old packages are always cleaned before checking for updates. 
*   -e | --exit-prompt:  Prompt for key press to exit script.
         Useful when executed from desktop icon rather than bash terminal.
