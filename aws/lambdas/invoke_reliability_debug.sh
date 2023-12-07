#!/bin/bash

#
# Helper script to invoke reliability lambda function
#

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_REGION=ca-central-1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp -a $SCRIPT_DIR/reliability/lib/. $SCRIPT_DIR/reliability/nodejs/node_modules

# Get Queue URL
QUEUE_URL=$(aws sqs get-queue-url --queue-name submission_processing.fifo --endpoint-url http://localhost:4566 --query QueueUrl --output text)


RAW_MESSAGE=$(aws sqs receive-message --queue-url $QUEUE_URL --max-number-of-messages 1 --visibility-timeout 60 --wait-time-seconds 2 --endpoint-url http://localhost:4566 --query 'Messages[0]')
if [[ $RAW_MESSAGE == "null" ]]; then
  echo "No messages to process"
  break
fi
RECEIPT_HANDLE=$(echo $RAW_MESSAGE | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['ReceiptHandle'])")
echo "Receipt Handle: $RECEIPT_HANDLE"
SUBMISSION_ID=$(echo $RAW_MESSAGE | python3 -c "import sys, json; data=json.load(sys.stdin); print(json.loads(data['Body'])['submissionID'])")
echo "SubmissionID: $SUBMISSION_ID"

echo "Running Reliability Queue Lambda"
echo '{"Records":[{"body": "{\"submissionID\": \"'$SUBMISSION_ID'\"}" }]}' | sam local invoke -t ./local_development/template.yml -d 9999 --event - "Reliability"

echo "Deleting message from SQS Queue"
aws sqs delete-message --queue-url $QUEUE_URL --receipt-handle $RECEIPT_HANDLE --endpoint-url http://localhost:4566 





