#!/bin/bash
# Rebuild DKMS modules for new kernels

# instruct bash to: 
#  -e "fail on non zero exit status"
#  -u "fail on non-defined variables"
#  -o pipefail "prevent errors in pipeline from being masked"
set -euo pipefail

# Check for root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

ls /var/lib/initramfs-tools | sudo xargs -n1 /usr/lib/dkms/dkms_autoinstaller start
