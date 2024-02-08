# Forms Terraform

Infrastructure as Code for the GC Forms environment.

## Contributing

Pull Requests in this repository require all commits to be signed before they can be merged. Please see [this guide](https://docs.github.com/en/github/authenticating-to-github/managing-commit-signature-verification) for more information.

## Running Lambdas and DBs locally

You will need to have the following installed on a macOS machine.

### Prerequisites:

- [Docker Hub](https://docs.docker.com/desktop/mac/install/) or [Colima](https://github.com/abiosoft/colima)

- Homebrew:

  ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- Terragrunt:

  1. `brew install warrensbox/tap/tfswitch`
  1. `tfswitch 1.6.6`
  1. `brew install warrensbox/tap/tgswitch`
  1. `tgswitch 0.54.8`

- Yarn: `brew install yarn`

- AWS CLI: `brew install awscli`

- AWS SAM CLI

  1. If you previously had it installed with Brew then you should first uninstall this package using `brew uninstall aws-sam-cli`
  1. To install the AWS SAM CLI tool, follow the instructions on https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html under "macOS" and "Command line - All users" (you will have to download the .pkg file and run a command to install it on your machine)

  Please note that the latest tested version of AWS SAM CLI with your infrastructure code was `1.99.0`.

### If using Colima

- Docker: `brew install docker docker-compose docker-credential-manager`

Modify the docker config file to use mac os keychain as `credStore`

```shell
nano ~/.docker/config.json

{
    ...
    "credsStore": "osxkeychain",
    ...
}
```

- Colima: `brew insteall colima`

Ensure that apps like AWS SAM can connect to the correct docker.sock

```shell
# as /var/ is a protected directory, we will need sudo
sudo ln ~/.colima/default/docker.sock /var/run

# we can verify this has worked by running
ls /var/run
# and confirming that docker.sock is now in the directory
```

Colima can be set as a service to start on login: `brew services start colima`

### Starting LocalStack and E2E testing from devcontainers

**# TODO Outdated #**

For instructions on how to run without using dev containers please skip to the next section.

1. forms-terraform:

```sh
# Build the local infrastructure (run on first setup and when there are Terraform changes)
make terragrunt

# Start the lambda functions
make lambdas
```

2. platform-forms-client:

```sh
# Install dependencies, run database migrations and start local server
yarn --cwd migrations install
yarn install
yarn dev
```

### Starting LocalStack and services without dev containers

#### TLDR

**Spare me the details and give me the commands**

Only do once as part of setup:

You will also have to supply the following environment variables and values to platform-forms-client to get everything working with the local lambdas and localstack.

```shell
# localstack only simulates a us-east-1 region
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_REGION=ca-central-1
RELIABILITY_FILE_STORAGE=forms-local-reliability-file-storage
LOCAL_AWS_ENDPOINT=http://127.0.0.1:4566
```

#### Set your environment variables (optional)

Copy the `.env.example` file and rename it to `.env`. Some of the variables require values that can be found in the 1Password shared secrets note.

#### Launch the infrastructure and the application

Everytime you want to run localstack and lambdas locally

1. In one terminal run `docker-compose up`
2. In a second terminal run `./localstack_services.sh`
3. In a third terminal in the `platform-forms-client` repo run `yarn dev`

#### It didn't work...I need the details

Once you have localstack installed you should be able to start the localstack container and services using the following command.

```shell
$ docker-compose up
```

You should see the following output if localstack has successfully started

```shell
❯ docker-compose up                                                                                                                                                                 ─╯
[+] Running 3/0
 ✔ Container GCForms_Redis       Created
 ✔ Container GCForms_DB          Created
 ✔ Container GCForms_LocalStack  Created
Attaching to GCForms_DB, GCForms_LocalStack, GCForms_Redis
GCForms_DB          |
GCForms_DB          |
GCForms_DB          | 2023-12-07 14:22:54.172 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
GCForms_DB          | 2023-12-07 14:22:54.173 UTC [1] LOG:  listening on IPv6 address "::", port 5432
GCForms_DB          | 2023-12-07 14:22:54.177 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
GCForms_DB          | 2023-12-07 14:22:54.198 UTC [26] LOG:  database system was shut down at 2023-12-07 14:13:14 UTC
GCForms_DB          | 2023-12-07 14:22:54.204 UTC [1] LOG:  database system is ready to accept connections
GCForms_Redis       | 1:C 07 Dec 2023 14:22:54.239 # WARNING Memory overcommit must be enabled! Without it, a background save or replication may fail under low memory condition. Being disabled, it can also cause failures without low memory condition, see https://github.com/jemalloc/jemalloc/issues/1328. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
GCForms_Redis       | 1:C 07 Dec 2023 14:22:54.239 * oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
GCForms_Redis       | 1:C 07 Dec 2023 14:22:54.239 * Redis version=7.2.3, bits=64, commit=00000000, modified=0, pid=1, just started
GCForms_Redis       | 1:C 07 Dec 2023 14:22:54.239 # Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf
GCForms_Redis       | 1:M 07 Dec 2023 14:22:54.239 * monotonic clock: POSIX clock_gettime
GCForms_Redis       | 1:M 07 Dec 2023 14:22:54.240 * Running mode=standalone, port=6379.
GCForms_Redis       | 1:M 07 Dec 2023 14:22:54.240 * Server initialized
GCForms_Redis       | 1:M 07 Dec 2023 14:22:54.240 * Loading RDB produced by version 7.2.3
GCForms_Redis       | 1:M 07 Dec 2023 14:22:54.240 * RDB age 579 seconds
GCForms_Redis       | 1:M 07 Dec 2023 14:22:54.240 * RDB memory usage when created 0.83 Mb
GCForms_Redis       | 1:M 07 Dec 2023 14:22:54.240 * Done loading RDB, keys loaded: 6, keys expired: 0.
GCForms_Redis       | 1:M 07 Dec 2023 14:22:54.241 * DB loaded from disk: 0.000 seconds
GCForms_Redis       | 1:M 07 Dec 2023 14:22:54.241 * Ready to accept connections tcp
GCForms_LocalStack  |
GCForms_LocalStack  | LocalStack version: 3.0.3.dev
GCForms_LocalStack  | LocalStack Docker container id: 0211f3486795
GCForms_LocalStack  | LocalStack build date: 2023-12-05
GCForms_LocalStack  | LocalStack build git hash: c1dcbc50
GCForms_LocalStack  |
GCForms_LocalStack  | 2023-12-07T14:22:56.069  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:4566 (CTRL + C to quit)
GCForms_LocalStack  | 2023-12-07T14:22:56.069  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:4566 (CTRL + C to quit)
GCForms_LocalStack  | Ready.
```

### Setting up local infrastructure

Now that we have localstack up and running it's time to configure our local AWS services to mimic our cloud environments

**Please note if you stop localstack you will need to run this script again**
**Localstack does not persist states between restarts of the service**

run `./localstack_services.sh`

Congratulations! You should now have all the necessary infrastructure configured on localstack to run lambda functions completely locally without needing an AWS account.

### Dynamo Database Table Schemas

#### Vault Table

##### Table

![Vault Table](./readme_images/Vault.png)

##### Archive Global Secondary Index

This Index supports the archiving of Vault responses
![Archive GSI](./readme_images/GSI_Vault_Archive.png)

##### Status Global Secondary Index

This Index supports the future feature of the Retrieval API. Essentially the ability to retrieve responses without using the Application Interface.
![Status Index](./readme_images/GSI_Vault_Status.png)

##### Nagware Global Secondary Index

This Index supports the Nagware feature. It gives the ability to retrieve form submissions with a specific status and creation date.
![Nagware Index](./readme_images/GSI_Vault_Nagware.png)

### Invoking Lambdas manually

**# TODO Update #**

**Lambda's are now invoked automatically similar to the cloud environment**

If you want to invoke a lambda specifically, here’s the example command:
`aws lambda invoke --function-name "Submission" --endpoint-url "http://127.0.0.1:3001" --no-verify-ssl --payload fileb://./file.json out.txt`
**NOTE:** _`fileb://` allows a JSON file that uses UTF-8 encoding for the payload._

Troubleshooting
db host env var: runs in docker - need to get localhost for host machine
if you get connection errors: postgresql.conf listen address “\*”

Notes:
When running locally using AWS SAM, the env var `LOCALSTACK = true` is set automatically - so I hook into this for local testing

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

#### Running the archive_form_templates lambda

Unfortunately due to AWS SAM limitations it is not possible to automatically trigger the archive_form_templates lambda function on a daily basis.

In order to run the archive_form_templates lambda you will have to call the `invoke_archive_form_templates.sh` script.

```shell
$ ./invoke_archive_form_templates.sh

Reading invoke payload from stdin (you can also pass it from file with --event)
Invoking archiver.handler (nodejs14.x)
ReliabilityLayer is a local Layer in the template
Building image.......................
Skip pulling image and use local one: samcli/lambda:nodejs14.x-x86_64-2ab34c74bed6bccfbae4c6fc8.

Mounting /Users/clementjanin/github/forms-terraform/aws/app/lambda/archive_form_templates as /var/task:ro,delegated inside runtime container
START RequestId: 9ce70de4-77c1-4a39-9d4e-e46bd73d1091 Version: $LATEST
END RequestId: 9ce70de4-77c1-4a39-9d4e-e46bd73d1091
REPORT RequestId: 9ce70de4-77c1-4a39-9d4e-e46bd73d1091	Init Duration: 0.05 ms	Duration: 426.80 ms	Billed Duration: 427 ms	Memory Size: 128 MB	Max Memory Used: 128 MB
{"statusCode":"SUCCESS"}
```

## Terraform secrets

Terraform will require the following variables to plan and apply:

```hcl
ecs_secret_token_secret # JSON Web Token signing secret
notify_api_key          # Notify API key to send messages
freshdesk_api_key       # FreshDesk API key to send messages
rds_db_password         # Database password
slack_webhook           # Slack webhook to send CloudWatch notifications
```
