# Load testing

Locust load tests that can be run in Lambda functions or locally.

## Lambda functions

You will need AWS access credentials for the target environment.

```sh
export AWS_DEFAULT_REGION=ca-central-1
./run_load_test_in_lambdas.py --help
```

Example of a load test session with 1 lambda running for 60 seconds and simulating traffic from 1 user.

```sh
./run_load_test_in_lambdas.py --function_name=load-testing --locust_file=./tests/test_global_system.py --locust_host=https://forms-staging.cdssandbox.xyz --threads=1 --time_limit=60 --locust_users=1
```

## Locally

You will need AWS access credentials for the target environment, along with the following environment variables set:

```sh
FORM_ID                      # Form ID to use for load testing
FORM_PRIVATE_KEY             # JSON private key for the form (must be from the `FORM_ID` form)
ZITADEL_APP_PRIVATE_KEY      # JSON private key for the Zitadel application that is used for access token introspection
SUBMIT_FORM_SERVER_ACTION_ID # NextJS server action identifier associated to 'submitForm' function
```

Once the variables are set, you can start the tests like so:

```sh
make install

locust -f tests/test_submit_through_client_with_file_upload.py --host=https://forms-staging.cdssandbox.xyz
```
