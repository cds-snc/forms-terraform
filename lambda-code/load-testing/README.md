# Load testing
Locust load tests that can be run in a Lambda function or locally.

## Locally
You will need AWS access credentials for the target environment, along with the following environment variables set:
```sh
FORM_ID                 # Form ID to use for load testing
FORM_PRIVATE_KEY        # JSON private key for the form (must be from the `FORM_ID` form)
ZITADEL_APP_PRIVATE_KEY # JSON private key for the Zitadel application that is used for access token introspection
```
Once the variables are set, you can start the tests like so:
```sh
make install
make locust
```