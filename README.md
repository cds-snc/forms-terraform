# Forms Terraform

Infrastructure as Code for the GC Forms environment.

## Running Lambdas and DBs locally

You will need to have the following installed on a MacOS machine.

Pre-requisites:
- Docker Hub: https://docs.docker.com/desktop/mac/install/

- Homebrew:
    ```bash
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     ```
- LocalStack : `brew install localstack`
- Terragrunt: 

  1. `brew install warrensbox/tap/tfswitch`
  1. `tfswitch 1.0.10`
  1. `brew install warrensbox/tap/tgswitch`
  1. `tgswitch 0.35.6`

- Yarn: `brew install yarn`

- AWS CLI: `brew install awscli`

- AWS SAM CLI

  Please run these commands to install the aws sam cli using homebrew. The AWS SAM CLI is what we use to run the lambda functions locally and invoke them.

  1. `brew tap aws/tap`
  1. `brew install aws-sam-cli`

- Postgres and PGAdmin
  1. `brew install postgresql`
  1. `brew install --cask pgadmin4`

### Starting LocalStack and E2E testing from devcontainers

1. forms-terraform: 
```sh
# Run Terragrunt to create the local infrastructure
make terragrunt

# Start the lambdas
make lambdas
```

1. platform-forms-client:
```sh
yarn --cwd migrations install
yarn install
yarn dev
```

### Starting LocalStack 

Once you have localstack installed you should be able to start the localstack container and services using the following command.

```shell
$ localstack start
```

You should see the following output if localstack has successfully started 

```shell

     __                     _______ __             __
    / /   ____  _________ _/ / ___// /_____ ______/ /__
   / /   / __ \/ ___/ __ `/ /\__ \/ __/ __ `/ ___/ //_/
  / /___/ /_/ / /__/ /_/ / /___/ / /_/ /_/ / /__/ ,<
 /_____/\____/\___/\__,_/_//____/\__/\__,_/\___/_/|_|

 💻 LocalStack CLI 0.13.3

[19:49:57] starting LocalStack in Docker mode 🐳                                                                                     localstack.py:115
2022-01-17T19:49:58.192:INFO:bootstrap.py: Execution of "prepare_host" took 741.40ms
─────────────────────────────────────────────────── LocalStack Runtime Log (press CTRL-C to quit) ─────────────
```

If you have installed localstack via pip (python's package manager) and are receiving command not found errors. Please ensure that your python's bin is directly in the `$PATH`. If you are using pyenv with shims... this will not work. You need to reference the bin of the python version you are using directly in the path.

If you want to additionally verify what localstack services are running you can issue the following command 

```shell
$ localstack status services
┏━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━┓
┃ Service                  ┃ Status    ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━┩
│ acm                      │ ✔ running │
│ apigateway               │ ✔ running │
│ cloudformation           │ ✔ running │
│ cloudwatch               │ ✔ running │
│ config                   │ ✔ running │
│ dynamodb                 │ ✔ running │
│ dynamodbstreams          │ ✔ running │
│ ec2                      │ ✔ running │
│ es                       │ ✔ running │
│ events                   │ ✔ running │
│ firehose                 │ ✔ running │
│ iam                      │ ✔ running │
│ kinesis                  │ ✔ running │
│ kms                      │ ✔ running │
│ lambda                   │ ✔ running │
│ logs                     │ ✔ running │
│ redshift                 │ ✔ running │
│ resource-groups          │ ✔ running │
│ resourcegroupstaggingapi │ ✔ running │
│ route53                  │ ✔ running │
│ s3                       │ ✔ running │
│ secretsmanager           │ ✔ running │
│ ses                      │ ✔ running │
│ sns                      │ ✔ running │
│ sqs                      │ ✔ running │
│ ssm                      │ ✔ running │
│ stepfunctions            │ ✔ running │
│ sts                      │ ✔ running │
│ support                  │ ✔ running │
│ swf                      │ ✔ running │
└──────────────────────────┴───────────┘
```

### Setting up AWS CLI to work with localstack

In order to have the SDKs properly working with localstack we need to correctly set up
our aws cli profiles.

Add the following configurations to `~/.aws/config` and `~/.aws/credentials`

`~/.aws/config`
```text
[profile local]
region = ca-central-1
output = yaml
```

`./aws/credentials`
```text
[local]
aws_access_key_id = test
aws_secret_access_key = test
```

**ensure that you do not have a default profile as this will cause errors**

### Setting up local infrastructure 

Now that we have localstack up and running it's time to configure our local AWS services with what the lambdas would expect as if running in an AWS environment.

You must configure the following in the order they appear otherwise this will fail.

**Please note if you stop localstack you will need to run through this process again to get it configured**

#### Setting up local KMS

The first thing to do is to deploy KMS. Navigate to `./env/local/kms` and use terragrunt to apply it to localstack. Here is an example with the expected output 

```shell
$ cd ./env/local/kms
$ terragrunt apply
# JSON showing changes 

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  ~ kms_key_cloudwatch_arn         = "arn:aws:kms:us-east-1:000000000000:key/4e4bf925-2704-4166-95e8-d61db99a5973" -> (known after apply)
  ~ kms_key_cloudwatch_us_east_arn = "arn:aws:kms:us-east-1:000000000000:key/0c5e0274-e380-4d74-97cb-7c4efcd3dae2" -> (known after apply)
  ~ kms_key_dynamodb_arn           = "arn:aws:kms:us-east-1:000000000000:key/f246fa41-5ae2-4c6f-a5d9-dc0d86b95ec4" -> (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_kms_key.cloudwatch_us_east: Creating...
aws_kms_key.dynamo_db: Creating...
aws_kms_key.cloudwatch: Creating...
aws_kms_key.cloudwatch: Still creating... [10s elapsed]
aws_kms_key.cloudwatch_us_east: Still creating... [10s elapsed]
aws_kms_key.dynamo_db: Still creating... [10s elapsed]
aws_kms_key.dynamo_db: Creation complete after 12s [id=bb42f69d-66e9-438e-b5a6-98fdb61d4cb2]
aws_kms_key.cloudwatch: Creation complete after 13s [id=7a777ca8-f0a7-40e6-baab-1d900343d7c6]
aws_kms_key.cloudwatch_us_east: Creation complete after 13s [id=14b40854-f2f6-4002-9385-46859a9a95e7]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

kms_key_cloudwatch_arn = "arn:aws:kms:us-east-1:000000000000:key/7a777ca8-f0a7-40e6-baab-1d900343d7c6"
kms_key_cloudwatch_us_east_arn = "arn:aws:kms:us-east-1:000000000000:key/14b40854-f2f6-4002-9385-46859a9a95e7"
kms_key_dynamodb_arn = "arn:aws:kms:us-east-1:000000000000:key/bb42f69d-66e9-438e-b5a6-98fdb61d4cb2"

```


#### Creating SQS queue

Now to create our local SQS queue.

Navigate to `./env/local/sqs` and use terragrunt to apply it to localstack. Here is an example with the expected output. 

```shell
$ cd ./env/local/sqs
$ terragrunt apply
# JSON of changes beforehand
Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  ~ sqs_reliability_queue_arn = "arn:aws:sqs:us-east-1:000000000000:submission_processing.fifo" -> (known after apply)
  ~ sqs_reliability_queue_id  = "http://localhost:4566/000000000000/submission_processing.fifo" -> (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_sqs_queue.deadletter_queue: Creating...
aws_sqs_queue.deadletter_queue: Creation complete after 1s [id=http://localhost:4566/000000000000/deadletter_queue.fifo]
aws_sqs_queue.reliability_queue: Creating...
aws_sqs_queue.reliability_queue: Creation complete after 0s [id=http://localhost:4566/000000000000/submission_processing.fifo]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

sqs_deadletter_queue_arn = "deadletter_queue.fifo"
sqs_reliability_queue_arn = "arn:aws:sqs:us-east-1:000000000000:submission_processing.fifo"
sqs_reliability_queue_id = "http://localhost:4566/000000000000/submission_processing.fifo"
```

#### Creating SNS queue

Now to create our local SNS queue.

Navigate to `./env/local/sns` and use terragrunt to apply it to localstack. Make sure you delete the terragrunt cache folder beforehand. Here is an example with the expected output. 

```shell
$ cd ./env/local/sns
$ rm -rf .terragrunt-cache
$ terragrunt apply
# JSON of changes beforehand
Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + sns_topic_alert_critical_arn        = (known after apply)
  + sns_topic_alert_ok_arn              = (known after apply)
  + sns_topic_alert_ok_us_east_arn      = (known after apply)
  + sns_topic_alert_warning_arn         = (known after apply)
  + sns_topic_alert_warning_us_east_arn = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_sns_topic.alert_warning_us_east: Creating...
aws_sns_topic.alert_ok_us_east: Creating...
aws_sns_topic.alert_warning_us_east: Creation complete after 0s [id=arn:aws:sns:us-east-1:000000000000:alert-warning]
aws_sns_topic.alert_ok_us_east: Creation complete after 0s [id=arn:aws:sns:us-east-1:000000000000:alert-ok]
aws_sns_topic.alert_warning: Creating...
aws_sns_topic.alert_critical: Creating...
aws_sns_topic.alert_ok: Creating...
aws_sns_topic.alert_critical: Creation complete after 0s [id=arn:aws:sns:us-east-1:000000000000:alert-critical]
aws_sns_topic.alert_warning: Creation complete after 0s [id=arn:aws:sns:us-east-1:000000000000:alert-warning]
aws_sns_topic.alert_ok: Creation complete after 0s [id=arn:aws:sns:us-east-1:000000000000:alert-ok]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

sns_topic_alert_critical_arn = "arn:aws:sns:us-east-1:000000000000:alert-critical"
sns_topic_alert_ok_arn = "arn:aws:sns:us-east-1:000000000000:alert-ok"
sns_topic_alert_ok_us_east_arn = "arn:aws:sns:us-east-1:000000000000:alert-ok"
sns_topic_alert_warning_arn = "arn:aws:sns:us-east-1:000000000000:alert-warning"
sns_topic_alert_warning_us_east_arn = "arn:aws:sns:us-east-1:000000000000:alert-warning"
```


#### Creating the DynamoDB database

Since we have configured KMS we can now configure our DynamoDB database.

Navigate to `./env/local/dynamodb` and use terragrunt apply to configure dynamodb on localstack. Here is an example with the expected output 

```shell
$ cd ./env/local/dynamodb
$ terragrunt apply
# JSON showing changes beforehand
Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  ~ dynamodb_relability_queue_arn = "arn:aws:dynamodb:us-east-1:000000000000:table/ReliabilityQueue" -> (known after apply)
  ~ dynamodb_vault_arn            = "arn:aws:dynamodb:us-east-1:000000000000:table/Vault" -> (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_dynamodb_table.reliability_queue: Creating...
aws_dynamodb_table.vault: Creating...
aws_dynamodb_table.reliability_queue: Creation complete after 0s [id=ReliabilityQueue]
aws_dynamodb_table.vault: Creation complete after 0s [id=Vault]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

dynamodb_relability_queue_arn = "arn:aws:dynamodb:us-east-1:000000000000:table/ReliabilityQueue"
dynamodb_vault_arn = "arn:aws:dynamodb:us-east-1:000000000000:table/Vault"
dynamodb_vault_retrieved_index_name = tolist([
  "retrieved-index",
])
dynamodb_vault_table_name = "Vault"
```

#### Creating the S3 buckets 

Now that we have everything configured it's time for the final step of configuring the s3 buckets.

Navigate to `./env/local/app` and use terragrunt apply to configure the s3 buckets on localstack. Please note that while the app TF module has a lot more than just configuring the s3 buckets, for the local environment we are only specifying to apply s3 configurations. Here is an example with the expected output

```shell
$ cd ./env/local/app
$ terragrunt apply
# JSON of changes beforehand
Plan: 6 to add, 0 to change, 0 to destroy.
╷
│ Warning: Resource targeting is in effect
│ 
│ You are creating a plan with the -target option, which means that the
│ result of this plan may not represent all of the changes requested by the
│ current configuration.
│               
│ The -target option is not for routine use, and is provided only for
│ exceptional situations such as recovering from errors or mistakes, or when
│ Terraform specifically suggests to use it as part of an error message.
╵

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_s3_bucket.vault_file_storage: Creating...
aws_s3_bucket.archive_storage: Creating...
aws_s3_bucket.reliability_file_storage: Creating...
aws_s3_bucket.vault_file_storage: Creation complete after 2s [id=forms-local-vault-file-storage]
aws_s3_bucket_public_access_block.vault_file_storage: Creating...
aws_s3_bucket_public_access_block.vault_file_storage: Creation complete after 0s [id=forms-local-vault-file-storage]
aws_s3_bucket.archive_storage: Creation complete after 2s [id=forms-local-archive-storage]
aws_s3_bucket_public_access_block.archive_storage: Creating...
aws_s3_bucket.reliability_file_storage: Creation complete after 3s [id=forms-local-reliability-file-storage]
aws_s3_bucket_public_access_block.reliability_file_storage: Creating...
aws_s3_bucket_public_access_block.archive_storage: Creation complete after 1s [id=forms-local-archive-storage]
aws_s3_bucket_public_access_block.reliability_file_storage: Creation complete after 0s [id=forms-local-reliability-file-storage]
╷
│ Warning: Applied changes may be incomplete
│ 
│ The plan was created with the -target option in effect, so some changes
│ requested in the configuration may have been ignored and the output values
│ may not be fully updated. Run the following command to verify that no other
│ changes are pending:
│     terraform plan
│       
│ Note that the -target option is not suitable for routine use, and is
│ provided only for exceptional situations such as recovering from errors or
│ mistakes, or when Terraform specifically suggests to use it as part of an
│ error message.
╵

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

You should now have all the necessary infrastructure configured on localstack to run lambda functions completely locally without needing an AWS account.

### Starting the environment:

In directory:
`./aws/app/lambda/local-development/`
`template.yml` defines the local environment / project we will be running. Functions and environment variables can be defined here.

Install Lambda dependencies and start local lambda service
In directory: `./aws/app/lambda/` run the script `./start_local_lambdas.sh`

If you want to invoke a lambda specifically, here’s the example command:
`aws lambda invoke --function-name "Templates" --endpoint-url "http://127.0.0.1:3001" --no-verify-ssl --payload fileb://./file.json out.txt`
**NOTE:** *`fileb://` allows a JSON file that uses UTF-8 encoding for the payload.*

Otherwise, in the platform-forms-client, you just modify the ‘endpoint’ parameter of the LambdaClient to hit `http://127.0.0.1:3001` . I’ve done this through an environment variable:
`LOCAL_LAMBDA_ENDPOINT=http://127.0.0.1:3001`

You will also have to supply the following environment variables and values to platform-forms-client to get everything working with the local lambdas and localstack.

```shell
# localstack only simulates a us-east-1 region
AWS_REGION=us-east-1
LOCAL_S3_ENDPOINT=http://localhost:4566
RELIABILITY_FILE_STORAGE=forms-local-reliability-file-storage
LOCAL_LAMBDA_ENDPOINT=http://127.0.0.1:3001
LOCAL_S3_ENDPOINT=http://localhost:4566
```

Troubleshooting
db host env var: runs in docker - need to get localhost for host machine
if you get connection errors: postgresql.conf listen address “\*”

Notes:
When running locally using AWS SAM, the env var `AWS_SAM_LOCAL = true` is set automatically - so I hook into this for local testing

#### Running the reliability lambda 

Unfortunately due to AWS SAM limitations it is not possible to automatically trigger the reliability lambda function whenever an event is pushed to the SQS queue via the Submission lambda. 

In order to run the reliability lambda. First spin up local lambdas using the `start_local_lambda` script and submit a form through the platform-forms-client.

You should see in the console the submission ID after the Submission function has successfully been invoked 

```shell
START RequestId: 21a1df8b-ed4b-4fd5-8dad-e92ee76341ee Version: $LATEST
2022-01-19T09:16:08.084Z        21a1df8b-ed4b-4fd5-8dad-e92ee76341ee    INFO    {"status": "success", "sqsMessage": "aab25a19-e12e-5e72-fcde-b26ca07b2cda", "submissionID": "2dd4930d-cd77-41b3-a68e-9f44ef9e80f5"}
END RequestId: 21a1df8b-ed4b-4fd5-8dad-e92ee76341ee
REPORT RequestId: 21a1df8b-ed4b-4fd5-8dad-e92ee76341ee  Init Duration: 0.48 ms  Duration: 797.46 ms     Billed Duration: 798 ms Memory Size: 128 MB     Max Memory Used: 128 MB 
2022-01-19 04:16:08 127.0.0.1 - - [19/Jan/2022 04:16:08] "POST /2015-03-31/functions/Submission/invocations HTTP/1.1" 200 -
```


You can then take this submission id and use the `invoke_reliability` script to simulate the reliability function being invoked by a SQS event.

```shell
$ ./invoke_reliability.sh 2dd4930d-cd77-41b3-a68e-9f44ef9e80f5
Reading invoke payload from stdin (you can also pass it from file with --event)
Invoking reliability.handler (nodejs14.x)
ReliabilityLayer is a local Layer in the template
Building image.......................
Skip pulling image and use local one: samcli/lambda:nodejs14.x-x86_64-2ab34c74bed6bccfbae4c6fc8.

Mounting /Users/omarnasr/Documents/work/forms-staging-terraform/aws/app/lambda/reliability as /var/task:ro,delegated inside runtime container
START RequestId: ca3b4eed-9c78-46b0-ab55-62ccb8a93357 Version: $LATEST
2022-01-19T09:19:07.811Z        ca3b4eed-9c78-46b0-ab55-62ccb8a93357    INFO    Lambda Template Client successfully triggered
2022-01-19T09:19:09.199Z        ca3b4eed-9c78-46b0-ab55-62ccb8a93357    INFO    {"status": "success", "submissionID": "2dd4930d-cd77-41b3-a68e-9f44ef9e80f5", "sqsMessage":"aab25a19-e12e-5e72-fcde-b26ca07b2cda", "method":"notify"}
{"$metadata":{"httpStatusCode":200,"requestId":"44208450-2823-491c-8fbd-47248443e97a","attempts":1,"totalRetryDelay":0},"ConsumedCapacity":{"CapacityUnits":1,"TableName":"ReliabilityQueue"}}END RequestId: ca3b4eed-9c78-46b0-ab55-62ccb8a93357
REPORT RequestId: ca3b4eed-9c78-46b0-ab55-62ccb8a93357  Init Duration: 0.17 ms  Duration: 8051.83 ms    Billed Duration: 8052 ms        Memory Size: 128 MB     Max Memory Used: 128 MB 
```

Please note you must configure the `NOTIFY_API_KEY` in the `templates.yml` for this to work. If you have configured it correctly... you should successfully receive an email with the form response 

#### Running the archiver lambda 

Unfortunately due to AWS SAM limitations it is not possible to automatically trigger the archiver lambda function whenever a modification is made to the DynamoDB Vault table.

In order to run the archiver lambda you should have the FormID and the SubmissionID in your possession so that you can pass them to the `invoke_archiver` script.

```shell
$ ./invoke_archiver.sh 1 2dd4930d-cd77-41b3-a68e-9f44ef9e80f5
Reading invoke payload from stdin (you can also pass it from file with --event)
Invoking archiver.handler (nodejs12.x)
ArchiverLayer is a local Layer in the template
Building image.......................
Skip pulling image and use local one: samcli/lambda:nodejs12.x-x86_64-201e8924bd486130d7628ec48.

Mounting /Users/clementjanin/github/forms-terraform/aws/app/lambda/archive_form_responses as /var/task:ro,delegated inside runtime container
START RequestId: fc1f1509-63af-4a96-a798-81a295e6ca2f Version: $LATEST
END RequestId: fc1f1509-63af-4a96-a798-81a295e6ca2f
REPORT RequestId: fc1f1509-63af-4a96-a798-81a295e6ca2f	Init Duration: 0.27 ms	Duration: 627.46 ms	Billed Duration: 628 ms	Memory Size: 128 MB	Max Memory Used: 128 MB
{"statusCode":"SUCCESS"}
```


## Terraform secrets
Terraform will require the following variables to plan and apply:
```hcl
ecs_secret_token_secret # JSON Web Token signing secret
google_client_id        # Google OAuth client ID (used for authentication)
google_client_secret:   # Google OAuth client secret (used for authentication)
notify_api_key          # Notify API key to send messages
rds_db_password         # Database password
slack_webhook           # Slack webhook to send CloudWatch notifications
```

