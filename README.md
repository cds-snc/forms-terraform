# Forms Terraform

Infrastructure as Code for the GC Forms environment.

## Contributing

Pull Requests in this repository require all commits to be signed before they can be merged. Please see [this guide](https://docs.github.com/en/github/authenticating-to-github/managing-commit-signature-verification) for more information.

## Prerequisites:

- [Docker Hub](https://docs.docker.com/desktop/mac/install/) or [Colima](https://github.com/abiosoft/colima)

- Homebrew:

  ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- Terragrunt:

  1. `brew install warrensbox/tap/tfswitch`
  1. `tfswitch 1.9.2`
  1. `brew install warrensbox/tap/tgswitch`
  1. `tgswitch 0.63.2`

- Yarn (if you want to deploy the infrastructure locally):

  ```shell
  $ brew install yarn
  ```

  (source https://classic.yarnpkg.com/lang/en/docs/install/#mac-stable)

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

- awslocal (if you want to deploy the infrastructure locally):

  ```shell
  $ brew install awscli-local
  ```

  (source https://formulae.brew.sh/formula/awscli-local)

  OR

  ```shell
  $ pip install awscli-local
  ```

  (source https://github.com/localstack/awscli-local)

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

- Colima: `brew install colima`

```shell
# as /var/ is a protected directory, we will need sudo
sudo ln ~/.colima/default/docker.sock /var/run

# we can verify this has worked by running
ls /var/run
# and confirming that docker.sock is now in the directory
```

Colima can be set as a service to start on login: `brew services start colima`

## Request Localstack Pro license

You will need to create a Localstack account using your CDS email address [here](https://app.localstack.cloud/sign-in) and then ask your supervisor to assign you a Pro license license.

## Set your environment variables

Create an `.env` file at the root of the project and use the `.env.example` as a template. You can find some of the values in 1Password > Local Development .ENV secure note. 
The `LOCALSTACK_AUTH_TOKEN` value will be accessible [here](https://app.localstack.cloud/workspace/auth-token) once you have been assigned a Pro license.

## Start Localstack

```shell
$ docker-compose up
```

<details>
<summary>See expected console output</summary>

```shell
[+] Building 0.0s (0/0)
[+] Running 2/2
 ✔ Network forms-terraform_default  Created                                                                               0.1s
 ✔ Container GCForms_LocalStack     Created                                                                               0.1s
Attaching to GCForms_LocalStack
GCForms_LocalStack  |
GCForms_LocalStack  | LocalStack version: 3.2.1.dev20240306170817
GCForms_LocalStack  | LocalStack Docker container id: 00e39dc6785e
GCForms_LocalStack  | LocalStack build date: 2024-03-06
GCForms_LocalStack  | LocalStack build git hash: 93fc329
GCForms_LocalStack  |
GCForms_LocalStack  | 2024-03-27T14:11:56.175  INFO --- [  MainThread] l.bootstrap.licensingv2    : Successfully requested and activated new license <license_identifier>:pro 🔑✅
GCForms_LocalStack  | 2024-03-27T14:11:58.611  INFO --- [  MainThread] l.p.snapshot.plugins       : registering ON_STARTUP load strategy
GCForms_LocalStack  | 2024-03-27T14:11:59.649  INFO --- [  MainThread] l.p.snapshot.plugins       : registering SCHEDULED save strategy
GCForms_LocalStack  | 2024-03-27T14:11:59.713  INFO --- [  MainThread] l.extensions.platform      : loaded 0 extensions
GCForms_LocalStack  | 2024-03-27T14:12:00.097  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:4566 (CTRL + C to quit)
GCForms_LocalStack  | 2024-03-27T14:12:00.097  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:4566 (CTRL + C to quit)
GCForms_LocalStack  | 2024-03-27T14:12:00.098  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:443 (CTRL + C to quit)
GCForms_LocalStack  | 2024-03-27T14:12:00.098  INFO --- [-functhread4] hypercorn.error            : Running on https://0.0.0.0:443 (CTRL + C to quit)
GCForms_LocalStack  | 2024-03-27T14:12:00.316  INFO --- [  MainThread] localstack.utils.bootstrap : Execution of "start_runtime_components" took 602.48ms
GCForms_LocalStack  | Ready.
GCForms_LocalStack  | 2024-03-27T14:12:03.093  INFO --- [  MainThread] l.p.snapshot.plugins       : restoring state of all services on startup
```

</details>

Once Localstack is ready to use you should be able to interact with local AWS services using the [Localstack web application](https://app.localstack.cloud/inst/default/resources).

**If the Localstack web application is not able to connect to the instance you just started you may have to add `127.0.0.1 localhost.localstack.cloud` to your `/etc/hosts`.**

## Deploy infrastructure

Now that we have localstack up and running it's time to deploy our local AWS services to mimic our cloud environments.

```shell
$ ./localstack_services.sh
```

**Please note that if you stop Localstack you don't need to run this script again.**
**Localstack Pro offers automatic persistence for all deployed services. This is enabled by default and can be tweaked through your `.env` file.**

Congratulations! You should now have all the necessary infrastructure configured on Localstack to support all the web applications functions completely locally without needing an AWS account.

## How to manually invoke a Lambda function

```shell
$ awslocal lambda invoke --function-name <name_of_the_function> output.txt
```

In case you want to invoke a function that expects a specific payload you can pass it using the `--payload '{}'` argument.

## Containerized Lambda functions

The `deps.sh` script allows you to download required dependencies for all Lambda packages available under `/lambda-code`.

```shell
$ cd lambda-code/
$ ./deps.sh install
```

Once you have changed the code in one or multiple Lambda packages, you can call the `deploy-lambda-images.sh`. It will build, tag and push all Lambda images to ECR as well as letting the Lambda service know that a new version of the code should be used.

```shell
$ cd lambda-code/
$ ./deploy-lambda-images.sh
```

**There is a `skip` argument you can pass to that script if you only want to deploy the Lambda images for which you have made changes. It uses the `git diff HEAD .` command in every single Lambda folder to know whether the image should be deployed or skipped**

## Dynamo Database Table Schemas

### Vault Table

#### Table

![Vault Table](./readme_images/Vault.png)

#### Archive Global Secondary Index

This Index supports the archiving of Vault responses
![Archive GSI](./readme_images/GSI_Vault_Archive.png)

#### Status Global Secondary Index

This Index supports the future feature of the Retrieval API. Essentially the ability to retrieve responses without using the Application Interface.
![Status Index](./readme_images/GSI_Vault_Status.png)

#### Nagware Global Secondary Index

This Index supports the Nagware feature. It gives the ability to retrieve form submissions with a specific status and creation date.
![Nagware Index](./readme_images/GSI_Vault_Nagware.png)

# Traduction en français à venir...
