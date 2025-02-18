#!/bin/bash

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color


export AWS_PROFILE="development"

basedir=$(pwd)

easyrsa_dir="$basedir/local_dev_files/easyrsa"

if [ ! -d "$easyrsa_dir" ]; then
  printf "${greenColor}Easy RSA not yet installed.${reset}\n"
  printf "${greenColor}Installing Easy RSA...${reset}\n"
  git clone https://github.com/OpenVPN/easy-rsa.git $easyrsa_dir  
else
    printf "${greenColor}Easy RSA already installed.${reset}\n"
fi

cd $easyrsa_dir/easyrsa3

if [ ! -d "$easyrsa_dir/easyrsa3/pki" ]; then
  printf "${greenColor}Easy RSA not yet initialized.${reset}\n"
  ./easyrsa init-pki 
fi

printf "${greenColor}Easy RSA Initialized...${reset}\n"
printf "${greenColor}Generating VPN certificates...${reset}\n"

./easyrsa --batch --req-cn=aws-development-ca build-ca nopass
./easyrsa --san=DNS:server --batch --req-cn=aws-development-server build-server-full aws-development-server nopass 
./easyrsa --batch build-client-full client.development.aws nopass


if [ ! -d "$basedir/aws/vpn/certificates" ]; then
  mkdir $basedir/aws/vpn/certificates
fi


  # Copy the server and client certificates to the local_dev_files directory
  cp $easyrsa_dir/easyrsa3/pki/ca.crt $basedir/local_dev_files/certificates/
  cp $easyrsa_dir/easyrsa3/pki/ca.crt $basedir/aws/vpn/certificates
  cp $easyrsa_dir/easyrsa3/pki/issued/aws-development-server.crt $basedir/aws/vpn/certificates
  cp $easyrsa_dir/easyrsa3/pki/private/aws-development-server.key $basedir/aws/vpn/certificates
  cp $easyrsa_dir/easyrsa3/pki/issued/client.development.aws.crt $basedir/local_dev_files/certificates
  cp $easyrsa_dir/easyrsa3/pki/private/client.development.aws.key $basedir/local_dev_files/certificates
   printf "${greenColor}VPN certificates initialized.${reset}\n"

