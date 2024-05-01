#!/bin/bash

# Exit on any error
set -e

ACTION=$1

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color

ecrRepositoryAddress=000000000000.dkr.ecr.ca-central-1.localhost.localstack.cloud:4511
lambdasToSkip=("cognito-email-sender", "cognito-pre-sign-up", "notify-slack", "load-testing")
basedir=$(pwd)

if ! command -v awslocal > /dev/null; then
  printf "${redColor}=> This script requires 'awslocal' to be installed.${reset}\n"
  exit 1
fi

printf "${greenColor}=> Building Lambda images${reset}\n"

for lambdaFolderPath in $basedir/*/; do
  lambdaName=$(basename $lambdaFolderPath)

  if [[ "${lambdasToSkip[@]}" =~ $lambdaName ]]; then
    printf "${yellowColor}=> Skipping $lambdaName Lambda as the associated resource is not deployed in Localstack.${reset}\n"
    continue
  fi

  cd $lambdaFolderPath

  if [[ "${ACTION}" == "skip" ]] && [[ $(git diff --cached -- .) == "" ]]; then
    printf "${yellowColor}=> Skipping $lambdaName Lambda as no code changes have been detected since last commit.${reset}\n"
  else
    printf "${greenColor}=> Building new ${lambdaName} image${reset}\n"

    repositoryName=${lambdaName}-lambda

    docker build -t $repositoryName .

    printf "${greenColor}=> Tagging and pushing ${lambdaName} image${reset}\n"

    docker tag $repositoryName $ecrRepositoryAddress/$repositoryName
    docker push $ecrRepositoryAddress/$repositoryName

    functionName=$([ "$lambdaName" == "submission" ] && echo "Submission" || echo "$lambdaName")

    printf "${yellowColor}=> Requesting ${functionName} Lambda function to use new image. It can fail if the Lambda function is not deployed yet.${reset}\n"

    awslocal lambda update-function-code --function-name $functionName --image-uri $ecrRepositoryAddress/$repositoryName > /dev/null || continue
  fi
done

printf "${greenColor}Completed deployment of Lambda images!${reset}\n"