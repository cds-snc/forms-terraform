#!/bin/bash

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color

basedir=$(pwd)

# Set proper terraform and terragrunt versions

tgswitch 0.75.10
tfswitch 1.11.2

if ! command -v openvpn >/dev/null; then
  printf "${redColor}=> This script requires 'openvpn' to be installed. See 'Prerequisites' section in the README file.${reset}\n"
  exit 1
fi

# Check if Endpoint exists

num_of_endpoints=$(aws ec2 describe-client-vpn-endpoints --query "length(ClientVpnEndpoints)")

if [[ "$num_of_endpoints" -eq 0 ]]; then
  printf "${redColor}=> VPN endpoint does not exist. Please build development environment with 'make build_env'.${reset}\n"
  exit 1
fi

if [[ "$num_of_endpoints" -gt 1 ]]; then
  printf "${redColor}=> Mulitiple VPN endpoints exist. Please build development environment with 'make build_env'.${reset}\n"
  exit 1
fi

# Check if VPN endpoint has subnet associations
vpn_endpoint_id=$(aws ec2 describe-client-vpn-endpoints --query "ClientVpnEndpoints[0].ClientVpnEndpointId" --output text)
num_of_associations=$(aws ec2 describe-client-vpn-target-networks \
  --client-vpn-endpoint-id $vpn_endpoint_id \
  --query "length(ClientVpnTargetNetworks[?Status.Code=='associated'])")
if [[ "$num_of_associations" -eq 0 ]]; then
  printf "${yellowColor}=> VPN endpoint does not have subnet associations.${reset}\n"
  printf "${greenColor}=> Running VPN terraform module.${reset}\n"
  # Build Lambda Scheduler
  cd $basedir/aws/vpn/lambda/code
  yarn build && yarn postbuild
  # Apply VPN terraform module
  cd $basedir/env/cloud/vpn
  terragrunt apply --non-interactive --log-level warn
fi

printf "${greenColor}=> VPN endpoint ${vpn_endpoint_id} has ${num_of_associations} subnet associations.${reset}\n"

# Get VPN endpoint DNS name

vpn_endpoint=$(aws ec2 describe-client-vpn-endpoints --query "ClientVpnEndpoints[0].DnsName" --output text | cut -c 3-)

printf "${greenColor}=> Connecting to VPN endpoint: $vpn_endpoint${reset}\n"

sudo openvpn --remote $vpn_endpoint 443 \
  --inactive 3600 \
  --ping 10 \
  --ping-exit 60 \
  --config $basedir/local_dev_files/certificates/client-config.ovpn \
  --ca $basedir/local_dev_files/certificates/ca.crt \
  --cert $basedir/local_dev_files/certificates/client.development.aws.crt \
  --key $basedir/local_dev_files/certificates/client.development.aws.key
