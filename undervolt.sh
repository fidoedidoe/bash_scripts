#!/bin/bash
# 
# Undervolt laptop using "intel-undervolt". 
#  Set undervolt values as defined in: /etc/intel-undervolt.conf
#  Currently undervolts: CPU, CPU Cache & Intel GPU

# instruct bash to: 
#  -e "fail on non zero exit status"
#  -u "fail on non-defined variables"
#  -o pipefail "prevent errors in pipeline from being masked"
set -euo pipefail

# Check for root
if [ "$EUID" -ne 0 ]
  then echo "undervolt.sh: Please run as root"
  exit
fi

intel-undervolt apply
