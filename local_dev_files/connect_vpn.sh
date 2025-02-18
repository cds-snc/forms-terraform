#!/bin/bash

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color


export AWS_PROFILE="development"

basedir=$(pwd)

if ! command -v openvpn > /dev/null; then
  printf "${redColor}=> This script requires 'openvpn' to be installed. See 'Prerequisites' section in the README file.${reset}\n"
  exit 1
fi

# Get VPN endpoint

vpn_endpoint=$(aws ec2 describe-client-vpn-endpoints --query "ClientVpnEndpoints[0].DnsName" --output text | cut -c 3-)

printf "${greenColor}=> Connecting to VPN endpoint: $vpn_endpoint${reset}\n"

sudo openvpn --remote $vpn_endpoint 443 --config $basedir/local_dev_files/certificates/client-config.ovpn \
  --ca $basedir/local_dev_files/certificates/ca.crt \
  --cert $basedir/local_dev_files/certificates/client.development.aws.crt \
  --key $basedir/local_dev_files/certificates/client.development.aws.key