const lambdaLocal = require('lambda-local');

/*
remove the skip to run the test
*/
test.skip('Investigate OpsGenie send function', async () => {
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
