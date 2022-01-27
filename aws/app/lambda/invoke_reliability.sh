#!/bin/bash

#
# Helper script to invoke reliability lambda function
#

SUBMISSION_ID=$1

cp -a ./reliability/lib/. ./reliability/nodejs/node_modules

echo '{"Records":[{"body": "{\"submissionID\": \"'$SUBMISSION_ID'\"}" }]}' | sam local invoke -t ./local_development/template.yml --event - "Reliability"