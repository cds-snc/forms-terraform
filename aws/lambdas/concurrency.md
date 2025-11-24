# The AWS Cloud has a total of 1000 concurrent execution environments

To ensure critical Lambda's alwasy have a minimum number of the execution environments
we reserve their concurrency. This way the other lambda functions cannot take priority and diminish critical functions.

Critical Lambdas:

- Submission: 150
- Reliability: 150
- Audit Logs: 5

The following concurrency limit is to force the Lambda to run synchronously

- File Upload Processor: 1
