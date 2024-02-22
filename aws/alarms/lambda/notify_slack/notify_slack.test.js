const lambdaLocal = require('lambda-local');
const zlib = require("zlib");

/*
remove the skip to run the test
*/
test.skip('Investigate OpsGenie send function for SNS SEV1', async () => {
    const result = await lambdaLocal.execute({
        event: {
            Records: [
                {
                    Sns: {
                        Message: JSON.stringify({
                            AlarmName: 'test-alarm-SEV1',
                            AlarmDescription: 'test-alarm-description',
                            NewStateValue: 'ALARM',
                            NewStateReason: 'test-alarm-reason',
                            StateChangeTime: '2023-07-13T13:48:30.151Z',
                            Region: 'us-west-2',
                        }),
                    },
                },
            ],
        },
        lambdaPath: 'notify_slack.js'
    });
});


/*
remove the skip to run the test
CloudWatch Logs are delivered to the subscribed Lambda function as a list that is gzip-compressed and base64-encoded. 

*/
test.skip('Investigate OpsGenie send function for Cloud Watch Log with severity=1', async () => {
    const logData = JSON.stringify({
        "messageType": "DATA_MESSAGE",
        "owner": "123456789123",
        "logGroup": "testLogGroup",
        "logStream": "testLogStream",
        "subscriptionFilters": [
            "testFilter"
        ],
        "logEvents": [
            {
                "id": "eventId1",
                "timestamp": 1440442987000,
                "message": `{
                    "level": "error",
                    "severity": 1,
                    "msg": "User clcqov5tv000689x5aib9uelt performed GrantFormAccess on Form clfsi1lva008789xagkeouz3w\\nAccess granted to bee@cds-snc.ca"
                }`

            }
        ]
    });
    const encodedData = compressAndEncode(logData);

    console.log(encodedData);

    const result = await lambdaLocal.execute({
        event: {
            "awslogs": {
                "data": `${encodedData}`
            }
        },
        lambdaPath: 'notify_slack.js'
    });
});

function compressAndEncode(data) {
    // Compress the data using zlib
    const compressedData = zlib.gzipSync(data);
    // Encode the compressed data using base64
    const encodedData = compressedData.toString('base64');
    return encodedData;
}
