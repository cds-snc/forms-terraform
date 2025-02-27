# Forms Terraform

Infrastructure as Code for the GC Forms environment.

## Contributing

Pull Requests in this repository require all commits to be signed before they can be merged. Please see [this guide](https://docs.github.com/en/github/authenticating-to-github/managing-commit-signature-verification) for more information.

## Prerequisites:

- [Colima](https://github.com/abiosoft/colima)

  1. Install Docker
     - `brew install docker docker-compose docker-credential-helper`
  1. Modify the docker config file to use mac os keychain as `credStore`

     ```shell
     nano ~/.docker/config.json

     {
     ...
     "credsStore": "osxkeychain",
     ...
     }
     ```

  1. Install Colima: `brew install colima`
  1. Add symlink to `/var/run`

     ```shell

     # as /var/ is a protected directory, we will need sudo
     sudo ln ~/.colima/default/docker.sock /var/run

     # we can verify this has worked by running
     ls /var/run
     # and confirming that docker.sock is now in the directory
     ```

  1. Colima can be set as a service to start on login: `brew services start colima`

- Homebrew:

  ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- Terragrunt:

  1. `brew install warrensbox/tap/tfswitch`
  1. `tfswitch 1.10.5`
  1. `brew install warrensbox/tap/tgswitch`
  1. `tgswitch 0.72.5`

- Yarn (chances are you already have this if working on the app):

  ```shell
  $ brew install yarn
  ```

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

  1. Install AWS CLI

  ```shell
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
  sudo installer -pkg AWSCLIV2.pkg -target /
  ```

- [OpenVPN](https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage):

  - `$ brew install openvpn`
  - In `.zprofile` add bin to Path: `export PATH="/usr/local/opt/openvpn/sbin:$PATH"`

## Set your environment variables

Create an `.env` file at the root of the project and use the `.env.example` as a template. You can find some of the values in 1Password > Local Development .ENV secure note.

```shell
AWS_ACCOUNT_ID=YOUR_AWS_SCRATCH_ACCOUNT_ID
STAGING_AWS_ACCOUNTID=CURRENT_STAGING_ACCOUNT_ID
```

## AWS CLI Crendentials

Add the following configuration to your `~/.aws/config` file

- The `sso_start_url` value can be found by asking one or your colleages
- The `sso_account_id` is your AWS Scratch Account ID

```
[sso-session CDS]
sso_start_url = https://***********.awsapps.com/start#
sso_region = ca-central-1
sso_registration_scopes = sso:account:access
[profile development]
sso_session = CDS
sso_account_id = ************
sso_role_name = AWSAdministratorAccess
region = ca-central-1
output = json
```

Once the configuration above is entered into the AWS CLI configuration a developer can generate credentials for the terminal by running:
`aws sso login --profile development`

This will open a browser window and ask you to go through the regular AWS Console login process. Once completed, or if you have already logged in that day, you will be presented with a message notifying you that the credentials have been supplied to the CLI.

## Building the Development Environment

### Creating VPN certificates

The first time you set up the development environment you will need to create PKI certificates in order to connect into the AWS VPC. This step is only needed the first time you build the environment or you delete the certificate folders.

```shell
$ make create_certs
```

### Deploying infrastructure as code into your scratch account

Please ensure you have run `aws sso login --profile development` before continuing.

```shell
$ make build_env
```

Copy the variables at the end of the output, as seen below, into your application folder's `.env` file.

```shell
All infratructure initialized: Ready for requests
=> Please copy the following to your app .env file:
AWS_PROFILE=development
DATABASE_URL=postgres://postgres:*********@forms-db-cluster.cluster-************.ca-central-1.rds.amazonaws.com:5432/forms?connect_timeout=60
REDIS_URL=gcforms-redis-rep-group-001.******.0001.cac1.cache.amazonaws.com:6379
RELIABILITY_FILE_STORAGE=forms-************-reliability-file-storage
```

### Connecting your local development GCForms app

The following command creates a vpn tunnel from your local machine into the VPC of the scratch account. This allows your local development environment to connect to backend services like RDS, SQS, Lambdas, and all the other AWS services the GCForms app leverages.

```shell
$ make connect_env
```

### Destroying infrastructure as code in your scratch account

To remove all infrastructure as code that was deployed you can simply run the following:

```shell
$ make destroy_env
```

This will remove all infrastructure created by terraform as well as terraform state and terraform lock resources. This will not remove any resources created by click ops in the AWS Console.

## Containerized Lambda functions

The `deps.sh` script allows you to download required dependencies for all Lambda packages available under `/lambda-code`.

```shell
$ cd lambda-code/
$ ./deps.sh install
```

Once you have changed the code in one or multiple Lambda packages, you can leverage the `make lambdas` or `make lambda [name]` commands. They will build, tag and push either all Lambda images or a specific image to your ECR as well as letting the Lambda service know that a new version of the code should be used.

## Dynamo Database Table Schemas

### Vault Table

#### Table

![Vault Table](./readme_images/Vault.png)

#### StatusCreatedAt Global Secondary Index

This Index supports the future feature of the GCForms API. Essentially the ability to retrieve responses without using the Application Interface.
![StatusCreatedAt Index](./readme_images/GSI_Vault_StatusCreatedAt.png)

# Traduction en français à venir...
