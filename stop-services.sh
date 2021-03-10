#!/bin/bash
# Rebuild DKMS modules for new kernels

# instruct bash to: 
#  -e "fail on non zero exit status"
#  -u "fail on non-defined variables"
#  -o pipefail "prevent errors in pipeline from being masked"
set -euo pipefail

# Check for root user
if [ "$EUID" -ne 0 ]
  then echo "dkms-rebuild-modules.sh: Please run as root"
  exit
fi

sudo service apache2 stop 
sudo service docker stop 
sudo service tor stop 
