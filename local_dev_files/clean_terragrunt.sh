#!/bin/bash

# Exit on any error
set -e

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color

basedir=$(pwd)

printf "${yellowColor}=>  Clearing local files terragrunt cache and lock files...${reset}\n"
for dir in $basedir/env/cloud/*/; do
    rm -rf "${dir}.terragrunt-cache"
    rm -f "${dir}.terraform.lock.hcl"
done

printf "${greenColor}=>  Local files cleared.${reset}\n"

printf "${yellowColor}=>  Clearing local terraform state files and backups...${reset}\n"
for file in $basedir/env/cloud/*/*.tfstate*; do
    rm -f $file
done
printf "${greenColor}=>  Local terraform state files and backups cleared.${reset}\n"
