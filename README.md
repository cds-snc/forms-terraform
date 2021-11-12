# forms-staging-terraform

Infrastructure as Code for GC Forms Staging environment

## Running Lambdas and DBs locally

Pre-requisites:
- Docker  
- Homebrew  
- AWS CLI (*configure with staging credentials and “ca-central-1”*)  
- Postgres and PGAdmin

Install AWS SAM-CLI
`brew tap aws/tap`
`brew install aws-sam-cli`

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

Troubleshooting
db host env var: runs in docker - need to get localhost for host machine
if you get connection errors: postgresql.conf listen address “\*”

Notes:
When running locally using AWS SAM, the env var `AWS_SAM_LOCAL = true` is set automatically - so I hook into this for local testing

todo: environment variables
