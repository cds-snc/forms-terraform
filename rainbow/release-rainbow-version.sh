#!/bin/bash

lambdaRoleArn=arn:aws:iam::211125634918:role/service-role/rainbow-version-role-exq2e5g4
listenerArn=arn:aws:elasticloadbalancing:ca-central-1:211125634918:listener/app/test/bb56f289fb3d5b8a/16b02b3c01acd58f

read -p "What is the release name? : " releaseName
read -p "What is the deployment identifier? : " deploymentId

echo "Create Lambda code ZIP file"

sed -e "s/\PLACEHOLDER/$releaseName/" base-index.mjs > index.mjs
zip -r index.zip index.mjs

echo "Create Lambda function"

lambdaArn=$(aws lambda create-function \
  --function-name "rainbow-release-$releaseName" \
  --role $lambdaRoleArn \
  --zip-file fileb://index.zip \
  --handler index.handler \
  --runtime nodejs22.x | jq -r ".FunctionArn")

echo "Create Target Group for new Lambda"

targetGroupArn=$(aws elbv2 create-target-group \
  --name "rainbow-release-$releaseName" \
  --target-type lambda | jq -r ".TargetGroups[0].TargetGroupArn")

aws lambda add-permission \
  --function-name "$lambdaArn" \
  --statement-id "elb$releaseName" \
  --principal elasticloadbalancing.amazonaws.com \
  --action lambda:InvokeFunction > /dev/null 2>&1

aws elbv2 register-targets \
  --target-group-arn "$targetGroupArn" \
  --targets Id="$lambdaArn"

echo "Create Load Balancer listener rule to route traffic with HTTP header x-deployment-id=$deploymentId to new Target Group"

lastListenerRulePriority=$(aws elbv2 describe-rules \
  --listener-arn $listenerArn \
  --no-paginate | jq -r ".Rules[0].Priority")

aws elbv2 create-rule \
  --listener-arn $listenerArn \
  --conditions "[{\"Field\":\"http-header\",\"HttpHeaderConfig\":{\"HttpHeaderName\":\"x-deployment-id\",\"Values\":[\"$deploymentId\"]}}]" \
  --priority $((lastListenerRulePriority+1)) \
  --actions Type=forward,TargetGroupArn="$targetGroupArn" \
  --tags Key=Name,Value="rainbow-release-$releaseName" > /dev/null 2>&1