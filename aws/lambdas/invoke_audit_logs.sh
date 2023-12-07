#!/bin/bash

#
# Helper script to invoke reliability lambda function
#

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_REGION=ca-central-1

# Get Queue URL
QUEUE_URL=$(aws sqs get-queue-url --queue-name audit_log_queue --endpoint-url http://localhost:4566 --query QueueUrl --output text)
PYTHON_CODE_LAMBDA_INPUT=$'
import sys, json
raw_data=sys.stdin.read()
data=json.loads(raw_data)
new_data=[]
for x in data: new_data.append({\'messageId\':x[\'MessageId\'], \'body\':x[\'Body\']})
print(json.dumps(new_data))
'

PYTHON_CODE_RECEIPT_HANDLES=$'
import sys, json
raw_data=sys.stdin.read()
data=json.loads(raw_data)
for x in data: print(x[\'ReceiptHandle\'])
'

while :; do
  RAW_MESSAGE=$(aws sqs receive-message --queue-url "$QUEUE_URL" --max-number-of-messages 10 --visibility-timeout 60 --wait-time-seconds 1 --endpoint-url http://localhost:4566 --query 'Messages' --output json)
  echo "Raw SQS Messages: $RAW_MESSAGE"

  if [[ $RAW_MESSAGE == "null" ]]; then
    echo "No messages to process"
    break
  fi

  RECEIPT_HANDLES=()
  while IFS='' read -r line; do RECEIPT_HANDLES+=("$line"); done < <(echo "$RAW_MESSAGE" | python3 -c "$PYTHON_CODE_RECEIPT_HANDLES")

  LAMBDA_INPUT=$(echo "$RAW_MESSAGE" | python3 -c "$PYTHON_CODE_LAMBDA_INPUT")

  echo "Running Audit Log Lambda"
  echo '{"Records":'"$LAMBDA_INPUT"'}' | sam local invoke -t ./local_development/template.yml --event - "AuditLogs"

  echo "Deleting message from SQS Queue"

  for i in "${RECEIPT_HANDLES[@]}"; do
    echo "Deleting Message: $i"
    aws sqs delete-message --queue-url "$QUEUE_URL" --receipt-handle "$i" --endpoint-url http://localhost:4566
  done

done
