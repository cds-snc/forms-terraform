#!/bin/bash

#
# Helper script to invoke archiver lambda function
#

FORM_ID=$1
SUBMISSION_ID=$2

echo '{"Records":[{"eventID":"c4ca4238a0b923820dcc509a6f75849a","dynamodb":{"NewImage":{"FormID":{"S":"'$FORM_ID'"},"SubmissionID":{"S":"'$SUBMISSION_ID'"},"FormSubmission":{"S":"custom payload which is not what is actually in the DynamoDB Vault table"}}}}]}' | sam local invoke -t ./local_development/template.yml --event - "Archiver"