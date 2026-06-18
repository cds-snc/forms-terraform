#!/bin/bash

# Exit on any error
set -e

LAMBDA_NAME=$1

# Text colors
greenColor='\033[0;32m'
yellowColor='\033[0;33m'
redColor='\033[0;31m'
reset='\033[0m' # No Color

basedir=$(pwd)

ecrRepositoryAddress="${AWS_ACCOUNT_ID}.dkr.ecr.ca-central-1.amazonaws.com"
lambdasToSkip=("cognito-email-sender" "cognito-pre-sign-up" "notify-slack" "load-testing" "api-end-to-end-test")
basedir="$(pwd)/lambda-code"

if ! command -v aws >/dev/null; then
  printf "${redColor}=> This script requires 'aws' cli to be installed.${reset}\n"
  exit 1
fi

# The following command will get the password and login to the ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $ecrRepositoryAddress

if [ -z "$LAMBDA_NAME" ]; then
  printf "${greenColor}=> Building All Lambda images${reset}\n"
else
  printf "${greenColor}=> Building ${LAMBDA_NAME} Lambda image${reset}\n"
  for lambdaFolderPath in $basedir/*/; do
    lambdaName=$(basename $lambdaFolderPath)
    if [ "$lambdaName" != "$LAMBDA_NAME" ]; then
      lambdasToSkip+=($lambdaName)
    fi
    continue
  done
fi

for lambdaFolderPath in $basedir/*/; do
  lambdaName=$(basename $lambdaFolderPath)

  if [[ ! " ${lambdasToSkip[@]} " =~ " ${lambdaName} " ]]; then
    cd $lambdaFolderPath

    printf "${greenColor}=> Building new ${lambdaName} image${reset}\n"

    repositoryName=${lambdaName}-lambda

    docker build --platform=linux/amd64 --provenance false -t $repositoryName .
    printf "${greenColor}=> Tagging and pushing ${lambdaName} image${reset}\n"

    docker tag $repositoryName $ecrRepositoryAddress/$repositoryName
    docker push $ecrRepositoryAddress/$repositoryName

    functionName=$([ "$lambdaName" == "submission" ] && echo "Submission" || echo "$lambdaName")
    printf "${yellowColor}=> Requesting ${functionName} Lambda function to use new image. It can fail if the Lambda function is not deployed yet.${reset}\n"

    aws lambda update-function-code --function-name $functionName --image-uri $ecrRepositoryAddress/$repositoryName:latest >/dev/null || continue
  else
    printf "${yellowColor}=> Skipping $lambdaName Lambda as the associated resource was not requested.${reset}\n"
  fi
done

printf "${greenColor}Completed deployment of Lambda images!${reset}\n"
