# Changelog

## [3.16.0](https://github.com/cds-snc/forms-terraform/compare/v3.15.0...v3.16.0) (2024-07-29)


### Features

* add API load balancer target group ([#736](https://github.com/cds-snc/forms-terraform/issues/736)) ([7e87c4e](https://github.com/cds-snc/forms-terraform/commit/7e87c4ebc8917ba5d16e208fd0c733bd117892ea))
* add read-only user for RDS connector ([#751](https://github.com/cds-snc/forms-terraform/issues/751)) ([0a3a853](https://github.com/cds-snc/forms-terraform/commit/0a3a853e0140df5ed8105764dbfa468a44bbf41f))
* deploy API ECS service in Staging ([#746](https://github.com/cds-snc/forms-terraform/issues/746)) ([64cd26d](https://github.com/cds-snc/forms-terraform/commit/64cd26df20999078de8c2aa007bda8b288001d40))
* Enable Athena Federated Query for RDS ([#745](https://github.com/cds-snc/forms-terraform/issues/745)) ([133145d](https://github.com/cds-snc/forms-terraform/commit/133145d49b6f95017ee3ba00b04fe53e4d863e93))


### Bug Fixes

* add API paths to WAF and fix healthcheck ([#747](https://github.com/cds-snc/forms-terraform/issues/747)) ([907c469](https://github.com/cds-snc/forms-terraform/commit/907c46944659345190e17974476018fb967728d5))
* Athena-DynamoDB connector policy ([#741](https://github.com/cds-snc/forms-terraform/issues/741)) ([dea7b19](https://github.com/cds-snc/forms-terraform/commit/dea7b19e430f7750f91f679e33c2473cc2dca858))
* combine API valid paths with app ([#748](https://github.com/cds-snc/forms-terraform/issues/748)) ([0185313](https://github.com/cds-snc/forms-terraform/commit/018531332b236726903c7c56861c58840df304df))
* create API certificate validation resource ([#744](https://github.com/cds-snc/forms-terraform/issues/744)) ([b4fb494](https://github.com/cds-snc/forms-terraform/commit/b4fb4941c82f039564b11cb660810b455350bfaa))
* create dedicated security group for connector ([#749](https://github.com/cds-snc/forms-terraform/issues/749)) ([a883778](https://github.com/cds-snc/forms-terraform/commit/a88377811e4ce2776710eb78dcc4f34694d517e0))
* downgrade local AWS provider ([#743](https://github.com/cds-snc/forms-terraform/issues/743)) ([bb92b87](https://github.com/cds-snc/forms-terraform/commit/bb92b87d0184f3355a2f4f115b6e69a5d73b6b99))
* S3 egress from the connector ([#750](https://github.com/cds-snc/forms-terraform/issues/750)) ([4d17823](https://github.com/cds-snc/forms-terraform/commit/4d1782341adadc3e06081d49fdb3a44162d0a638))

## [3.15.0](https://github.com/cds-snc/forms-terraform/compare/v3.14.1...v3.15.0) (2024-07-23)


### Features

* add API ECS service to the Forms cluster ([#734](https://github.com/cds-snc/forms-terraform/issues/734)) ([62d1753](https://github.com/cds-snc/forms-terraform/commit/62d17539f23ab03f40f3d3942989bd1db201d881))


### Bug Fixes

* block invalid `host` requests to the IdP ([#732](https://github.com/cds-snc/forms-terraform/issues/732)) ([7ad863d](https://github.com/cds-snc/forms-terraform/commit/7ad863d62db68bf1f0efccb041c88eacd2bbae80))
* convert LB security rules to standalone ([#740](https://github.com/cds-snc/forms-terraform/issues/740)) ([443fe06](https://github.com/cds-snc/forms-terraform/commit/443fe0684a08ecb0c02e68e8faf7d045e4243ef3))
* terraform script for athena-dynamodb ([#738](https://github.com/cds-snc/forms-terraform/issues/738)) ([0d16981](https://github.com/cds-snc/forms-terraform/commit/0d169819b755ff599764aef5190580104f9d9868))
* Use a custom policy for the dynamodb-lambda connector (allows access to AuditLog only) ([#731](https://github.com/cds-snc/forms-terraform/issues/731)) ([089f27d](https://github.com/cds-snc/forms-terraform/commit/089f27d8009458be3f216a73a446a07e6ff4e239))


### Miscellaneous Chores

* upgrade to latest Terraform and Terragrunt ([#735](https://github.com/cds-snc/forms-terraform/issues/735)) ([c21f697](https://github.com/cds-snc/forms-terraform/commit/c21f697c631ab3b4d82e853e3202f99193e395c1))
* upgrade to latest Terraform AWS provider ([#739](https://github.com/cds-snc/forms-terraform/issues/739)) ([981e82f](https://github.com/cds-snc/forms-terraform/commit/981e82f1437c5a844785241d96426ecbd76e2623))

## [3.14.1](https://github.com/cds-snc/forms-terraform/compare/v3.14.0...v3.14.1) (2024-07-18)


### Bug Fixes

* `alarm` module apply when `idp` not enabled ([#728](https://github.com/cds-snc/forms-terraform/issues/728)) ([e48896e](https://github.com/cds-snc/forms-terraform/commit/e48896e7637ec6c97dfea72dc9bbf70889733985))
* response archiver lambda will ignore confirmation code entries in the DynamoDB Vault table when scanning for items ([#730](https://github.com/cds-snc/forms-terraform/issues/730)) ([dbd7242](https://github.com/cds-snc/forms-terraform/commit/dbd7242fbd5beb173c257a1e1fbcedf8c08e2bde))

## [3.14.0](https://github.com/cds-snc/forms-terraform/compare/v3.13.0...v3.14.0) (2024-07-16)


### Features

* add IdP CloudWatch alarms ([#720](https://github.com/cds-snc/forms-terraform/issues/720)) ([f2696eb](https://github.com/cds-snc/forms-terraform/commit/f2696eb3fb480a92fe943e384ba6c6b775a1c4f4))
* Enable Amazon Athena to communicate with DynamoDB ([#723](https://github.com/cds-snc/forms-terraform/issues/723)) ([188824d](https://github.com/cds-snc/forms-terraform/commit/188824d2930dfb38329a20f5126f0992cd947daa))


### Bug Fixes

* Change the Archive Index key projection back to All ([#727](https://github.com/cds-snc/forms-terraform/issues/727)) ([4cdccf5](https://github.com/cds-snc/forms-terraform/commit/4cdccf5fd0b5185ea7e568fcf6c8815303f4a186))
* Updates global indexes to only project needed keys ([#725](https://github.com/cds-snc/forms-terraform/issues/725)) ([78ef137](https://github.com/cds-snc/forms-terraform/commit/78ef137cb7fb89bd076da24491c262769ee50024))


### Miscellaneous Chores

* **deps:** update all non-major github action dependencies ([#721](https://github.com/cds-snc/forms-terraform/issues/721)) ([aa42dae](https://github.com/cds-snc/forms-terraform/commit/aa42dae6dd650e52cf415618d4d4097caed13eb8))
* switch from using GSIs to Scan operations for both the response archiver and the nagware lambda functions ([#726](https://github.com/cds-snc/forms-terraform/issues/726)) ([c09caba](https://github.com/cds-snc/forms-terraform/commit/c09cabaa08176d05d5d34d057a4b48f243ed768d))
* synced file(s) with cds-snc/site-reliability-engineering ([#722](https://github.com/cds-snc/forms-terraform/issues/722)) ([605faef](https://github.com/cds-snc/forms-terraform/commit/605faef6ff1d157581d7ded4e2add58f0c38e607))

## [3.13.0](https://github.com/cds-snc/forms-terraform/compare/v3.12.0...v3.13.0) (2024-07-05)


### Features

* increase the number of form viewer tasks in prod ([#717](https://github.com/cds-snc/forms-terraform/issues/717)) ([0a252de](https://github.com/cds-snc/forms-terraform/commit/0a252def72117fc0f3e0526f49c324754d6b680b))


### Bug Fixes

* scale Staging to multiple ECS tasks ([#719](https://github.com/cds-snc/forms-terraform/issues/719)) ([2e45c8b](https://github.com/cds-snc/forms-terraform/commit/2e45c8b9a5759b8640a92119dee4576928b531a1))

## [3.12.0](https://github.com/cds-snc/forms-terraform/compare/v3.11.1...v3.12.0) (2024-07-04)


### Features

* add IdP Staging Terraform plan/apply steps ([#714](https://github.com/cds-snc/forms-terraform/issues/714)) ([c3f3958](https://github.com/cds-snc/forms-terraform/commit/c3f395857e5f391811f72d38aee247e48505fada))
* add module for Zitadel IdP infrastructure ([#708](https://github.com/cds-snc/forms-terraform/issues/708)) ([c6835b2](https://github.com/cds-snc/forms-terraform/commit/c6835b296cdbf088f9b5ddb8c6001475c4dad57c))
* add SPF, DKIM and DMARC DNS records ([#716](https://github.com/cds-snc/forms-terraform/issues/716)) ([e6b9641](https://github.com/cds-snc/forms-terraform/commit/e6b9641bc39ae534b6568d6b7e75e3aed416f136))
* send IdP emails using SES SMTP server ([#715](https://github.com/cds-snc/forms-terraform/issues/715)) ([f1150e7](https://github.com/cds-snc/forms-terraform/commit/f1150e776751aefa89bdc98241a57af1b8050413))


### Bug Fixes

* fix overdue response url ([#712](https://github.com/cds-snc/forms-terraform/issues/712)) ([b109fd5](https://github.com/cds-snc/forms-terraform/commit/b109fd51744c67b6d1670e037ecc6bd23e76099f))


### Miscellaneous Chores

* synced file(s) with cds-snc/site-reliability-engineering ([#707](https://github.com/cds-snc/forms-terraform/issues/707)) ([324cea1](https://github.com/cds-snc/forms-terraform/commit/324cea120c27dced4612c2d901990c362777154e))

## [3.11.1](https://github.com/cds-snc/forms-terraform/compare/v3.11.0...v3.11.1) (2024-06-27)


### Bug Fixes

* ECS task definition constant change on TF plan ([#709](https://github.com/cds-snc/forms-terraform/issues/709)) ([20e0a2e](https://github.com/cds-snc/forms-terraform/commit/20e0a2ef6e56c63dd1fe641c7620e3ed9838390a))

## [3.11.0](https://github.com/cds-snc/forms-terraform/compare/v3.10.2...v3.11.0) (2024-06-24)


### Features

* add CloudWatch Lambda function invocation alarms ([#706](https://github.com/cds-snc/forms-terraform/issues/706)) ([24a6cd6](https://github.com/cds-snc/forms-terraform/commit/24a6cd64f693287f4f82d1fee5a8e3ac5ab70212))
* health check alarm for submission lambda invocations ([#703](https://github.com/cds-snc/forms-terraform/issues/703)) ([4795366](https://github.com/cds-snc/forms-terraform/commit/47953660088469dd72c380c3393227f747d2cc83))


### Bug Fixes

* switch dashboard to log insight graphs ([#702](https://github.com/cds-snc/forms-terraform/issues/702)) ([5d741df](https://github.com/cds-snc/forms-terraform/commit/5d741dff1514cb5e2fac3b8084f79da8d0a6dab0))


### Miscellaneous Chores

* **deps:** update actions/checkout action to v4.1.7 ([#705](https://github.com/cds-snc/forms-terraform/issues/705)) ([77f33c4](https://github.com/cds-snc/forms-terraform/commit/77f33c44abe7c4b0ea456ca5830e30c35a2a3b47))
* solidify lambda functions matrix definition using a configuration file where we list functions that need to be deployed in production ([#699](https://github.com/cds-snc/forms-terraform/issues/699)) ([4ea0a7f](https://github.com/cds-snc/forms-terraform/commit/4ea0a7f886e77dd4fcc4813b22ef66a2362867bb))
* synced file(s) with cds-snc/site-reliability-engineering ([#693](https://github.com/cds-snc/forms-terraform/issues/693)) ([7f26d0e](https://github.com/cds-snc/forms-terraform/commit/7f26d0e3ff17f1d180f2cd627555e544a3e2fac4))

## [3.10.2](https://github.com/cds-snc/forms-terraform/compare/v3.10.1...v3.10.2) (2024-06-18)


### Bug Fixes

* remove custom health check metrics ([#698](https://github.com/cds-snc/forms-terraform/issues/698)) ([cbd6fac](https://github.com/cds-snc/forms-terraform/commit/cbd6facc5e6de5b6c79c75bd460370cc6433b921))


### Miscellaneous Chores

* remove `forms-terraform-apply-release` OIDC role ([#696](https://github.com/cds-snc/forms-terraform/issues/696)) ([69bb7e1](https://github.com/cds-snc/forms-terraform/commit/69bb7e1817c15a1be063923919ba68157e9f7849))

## [3.10.1](https://github.com/cds-snc/forms-terraform/compare/v3.10.0...v3.10.1) (2024-06-18)


### Bug Fixes

* use correct IAM role for TF apply ([#694](https://github.com/cds-snc/forms-terraform/issues/694)) ([d32fecd](https://github.com/cds-snc/forms-terraform/commit/d32fecd507de6c0b5bee799aeda6e139b5911425))

## [3.10.0](https://github.com/cds-snc/forms-terraform/compare/v3.9.4...v3.10.0) (2024-06-17)


### Features

* add CloudWatch metrics for Lambda behaviour ([#683](https://github.com/cds-snc/forms-terraform/issues/683)) ([489db64](https://github.com/cds-snc/forms-terraform/commit/489db64b8f409abd58aa74712a78cb7e7178d76b))
* add form submission health check metrics ([#681](https://github.com/cds-snc/forms-terraform/issues/681)) ([182e920](https://github.com/cds-snc/forms-terraform/commit/182e920835b6bd5b878461cdce4a004732a5e426))
* add health dashboard sections ([#692](https://github.com/cds-snc/forms-terraform/issues/692)) ([142e41d](https://github.com/cds-snc/forms-terraform/commit/142e41d352005b299e03921b181d043cb22eccd0))
* add system health dashboard ([#688](https://github.com/cds-snc/forms-terraform/issues/688)) ([74b810f](https://github.com/cds-snc/forms-terraform/commit/74b810fc543d2bf021d05b2c3f34ad2e68bc4427))
* add workflow to catch release of reverted tags ([#684](https://github.com/cds-snc/forms-terraform/issues/684)) ([bde87ea](https://github.com/cds-snc/forms-terraform/commit/bde87eabad0a4d107181d9ee3bab03d5cc1b6a88))
* connects new healthchecks logs from web app in GC Forms healtcheck dashboard ([#689](https://github.com/cds-snc/forms-terraform/issues/689)) ([f908efd](https://github.com/cds-snc/forms-terraform/commit/f908efd61061ee0f4e0a916a89c4d9d730702fba))
* simplify production release reverts ([#678](https://github.com/cds-snc/forms-terraform/issues/678)) ([f8af121](https://github.com/cds-snc/forms-terraform/commit/f8af1217b81b8a8a690f9f4527321da83be71160))


### Bug Fixes

* Athena load balancer create table query ([#679](https://github.com/cds-snc/forms-terraform/issues/679)) ([140a250](https://github.com/cds-snc/forms-terraform/commit/140a250c42dadeac7de4f574809ae761376d147c))
* checkout code for update lambda workflow step ([#685](https://github.com/cds-snc/forms-terraform/issues/685)) ([944fdf8](https://github.com/cds-snc/forms-terraform/commit/944fdf81fd24c408729344b1967d328f7a95e3a3))
* healthchecks dashboard layout is broken ([#690](https://github.com/cds-snc/forms-terraform/issues/690)) ([e45dff3](https://github.com/cds-snc/forms-terraform/commit/e45dff37b10add9ba8507cbc0a736f346e7e82c8))


### Miscellaneous Chores

* **deps:** update actions/checkout action to v4 ([#686](https://github.com/cds-snc/forms-terraform/issues/686)) ([a3bdd69](https://github.com/cds-snc/forms-terraform/commit/a3bdd69f071e3ec9015cd220a85054ddfddad7c6))
* **deps:** update actions/github-script action to v7 ([#687](https://github.com/cds-snc/forms-terraform/issues/687)) ([a7f1bc4](https://github.com/cds-snc/forms-terraform/commit/a7f1bc480f0e990e0c32327ef358bfc2adf5c063))
* **deps:** update all non-major docker images ([#636](https://github.com/cds-snc/forms-terraform/issues/636)) ([2ac8525](https://github.com/cds-snc/forms-terraform/commit/2ac8525e6ca6b9f1690b3b0ceb8410fb3b56d2c8))
* **deps:** update all non-major github action dependencies ([#549](https://github.com/cds-snc/forms-terraform/issues/549)) ([554e8b6](https://github.com/cds-snc/forms-terraform/commit/554e8b69827c7c4a7c6560ae93637b7a4ae90645))
* **deps:** update localstack/localstack docker digest to c7a01ee ([#691](https://github.com/cds-snc/forms-terraform/issues/691)) ([2f73044](https://github.com/cds-snc/forms-terraform/commit/2f73044c7c321332c5f519945caaa0194f0c67b2))
* synced file(s) with cds-snc/site-reliability-engineering ([#665](https://github.com/cds-snc/forms-terraform/issues/665)) ([a671f77](https://github.com/cds-snc/forms-terraform/commit/a671f7738bfd384b9449dc4f026ee0bed33cc941))
* update codeowners to protect version.txt ([#682](https://github.com/cds-snc/forms-terraform/issues/682)) ([7098c54](https://github.com/cds-snc/forms-terraform/commit/7098c54e8a091aa06e4ec326913706fdc814cf71))

## [3.9.4](https://github.com/cds-snc/forms-terraform/compare/v3.9.3...v3.9.4) (2024-06-04)


### Bug Fixes

* remove use of `always()` in the TF apply jobs ([#672](https://github.com/cds-snc/forms-terraform/issues/672)) ([01d12fa](https://github.com/cds-snc/forms-terraform/commit/01d12fa7068553e40206df28060dcac3f2b5a7e3))

## [3.9.3](https://github.com/cds-snc/forms-terraform/compare/v3.9.2...v3.9.3) (2024-06-03)


### Bug Fixes

* remove load-testing lambda deployment from apply production workflow ([#675](https://github.com/cds-snc/forms-terraform/issues/675)) ([62a7e26](https://github.com/cds-snc/forms-terraform/commit/62a7e26504376185176d8f022e9216fd5e934b13))


### Miscellaneous Chores

* add more information to the error message we get when failing to save a submission ([#673](https://github.com/cds-snc/forms-terraform/issues/673)) ([1265b9c](https://github.com/cds-snc/forms-terraform/commit/1265b9cef12ca48bc1e9f7c0b694407586800976))
* fix Lambda deployment issue with Localstack ([#676](https://github.com/cds-snc/forms-terraform/issues/676)) ([860136b](https://github.com/cds-snc/forms-terraform/commit/860136b614f968e1d3f2d81042133f56a1a9f8d0))

## [3.9.2](https://github.com/cds-snc/forms-terraform/compare/v3.9.1...v3.9.2) (2024-05-30)


### Bug Fixes

* Remove CSRF regex pattern from WAF out-of-country rule ([#671](https://github.com/cds-snc/forms-terraform/issues/671)) ([6e98154](https://github.com/cds-snc/forms-terraform/commit/6e981540fcf1e93d6f7e2c04c4d6b1f0b0ca6755))


### Miscellaneous Chores

* use static array of lambda name when deploying to production ([#669](https://github.com/cds-snc/forms-terraform/issues/669)) ([15baf0b](https://github.com/cds-snc/forms-terraform/commit/15baf0b2a178ef933e63d4b2f5e2978dcc0a5af3))

## [3.9.1](https://github.com/cds-snc/forms-terraform/compare/v3.9.0...v3.9.1) (2024-05-30)


### Bug Fixes

* deployment issue in production ([#668](https://github.com/cds-snc/forms-terraform/issues/668)) ([64f08d8](https://github.com/cds-snc/forms-terraform/commit/64f08d879d88357cf9835c53cb7e674a05890b39))
* production deployment issue ([#666](https://github.com/cds-snc/forms-terraform/issues/666)) ([35361dd](https://github.com/cds-snc/forms-terraform/commit/35361dddb695b9d323c6e8421a880916f2860bf0))

## [3.9.0](https://github.com/cds-snc/forms-terraform/compare/v3.8.5...v3.9.0) (2024-05-17)


### Features

* add TF_VAR check and conventional commit lint workflows ([#663](https://github.com/cds-snc/forms-terraform/issues/663)) ([bf44015](https://github.com/cds-snc/forms-terraform/commit/bf4401501858e352494e35c3fecae8cd153082e6))


### Bug Fixes

* include the mfa endpoint for WAF detection ([0a3baea](https://github.com/cds-snc/forms-terraform/commit/0a3baea9eb149d27982ccf112473034ba7d2e77f))
* missing runs on property in Github workflow ([#647](https://github.com/cds-snc/forms-terraform/issues/647)) ([94b3e2f](https://github.com/cds-snc/forms-terraform/commit/94b3e2ff5f2a88bf545eba2a9869934d39d27afd))
* modify the load balancer endpoint so it works with both the pre-app router and the new app router ([7a16224](https://github.com/cds-snc/forms-terraform/commit/7a16224864a83f8b7fea7a168b1e19248d2e56b2))
* notify slack lambda function had missing scripts in package.json ([#660](https://github.com/cds-snc/forms-terraform/issues/660)) ([db9f8cd](https://github.com/cds-snc/forms-terraform/commit/db9f8cd2e1005c1752c2e1fd1af8943c418b0592))
* Update Notify error handling across lambdas ([#651](https://github.com/cds-snc/forms-terraform/issues/651)) ([de189e2](https://github.com/cds-snc/forms-terraform/commit/de189e2c587cb936dcfbae3f28b446f858268a75))
* wrong job dependency name in Github Workflow ([#648](https://github.com/cds-snc/forms-terraform/issues/648)) ([342ecb1](https://github.com/cds-snc/forms-terraform/commit/342ecb11dced01fd831d27fefa013d6b877817c8))


### Miscellaneous Chores

* add permission for ECS task to call legacy submission Lambda function name ([#643](https://github.com/cds-snc/forms-terraform/issues/643)) ([66f98b9](https://github.com/cds-snc/forms-terraform/commit/66f98b92e41c52d0c2651fd11e9914d4cbc5517d))
* added description in all package.json files ([#649](https://github.com/cds-snc/forms-terraform/issues/649)) ([2b7ea5c](https://github.com/cds-snc/forms-terraform/commit/2b7ea5cbaa21b71d8c786f6511342fdfd28a7683))
* added test-lambda-code job to Github workflow ([#658](https://github.com/cds-snc/forms-terraform/issues/658)) ([87c2939](https://github.com/cds-snc/forms-terraform/commit/87c29391328a9c6555df69155d4c0312b6f6c50a))
* adjust WAF rules ([e9a3b8a](https://github.com/cds-snc/forms-terraform/commit/e9a3b8af5c1cfebce59001d50f39b8e169e3fb49))
* Disable OpsGenie alerting for non-production environment ([72fc8cb](https://github.com/cds-snc/forms-terraform/commit/72fc8cbdf3a92b71781bd6d33095e7cbf4554c1d))
* Github workflow deployment script not working as intended ([#655](https://github.com/cds-snc/forms-terraform/issues/655)) ([f6d16cf](https://github.com/cds-snc/forms-terraform/commit/f6d16cf9e9eac1559e10b095072cc2fc4b4c1e06))
* sanitize GitHub workflow logs ([e7e9537](https://github.com/cds-snc/forms-terraform/commit/e7e953751fc5bc905b22bcb37bf4d1c483ee8a6c))
* wait for lambdas images to be ready to use before applying Terraform modules ([#650](https://github.com/cds-snc/forms-terraform/issues/650)) ([3ca2993](https://github.com/cds-snc/forms-terraform/commit/3ca2993cac9cfaa02b7c62574a1b449bb09576cd))


### Code Refactoring

* convert Lambda code from S3 binary object to ECR container image ([#626](https://github.com/cds-snc/forms-terraform/issues/626)) ([524d68f](https://github.com/cds-snc/forms-terraform/commit/524d68f8f6d58e3a9601ff17e08438f6c0ce9bdc))

## [3.8.5](https://github.com/cds-snc/forms-terraform/compare/v3.8.4...v3.8.5) (2024-04-30)


### Miscellaneous Chores

* set force_destroy to true on Lambda code bucket in preparation for the Lambda containerization upgrade which will delete this bucket ([#641](https://github.com/cds-snc/forms-terraform/issues/641)) ([a20e4cb](https://github.com/cds-snc/forms-terraform/commit/a20e4cb7c6d5c04815e7c1a2c848ec59535301b3))

## [3.8.4](https://github.com/cds-snc/forms-terraform/compare/v3.8.3...v3.8.4) (2024-04-23)


### Bug Fixes

* update name of Notify callback token TF variable ([#639](https://github.com/cds-snc/forms-terraform/issues/639)) ([269ac5a](https://github.com/cds-snc/forms-terraform/commit/269ac5a6d2c6922e65f587094855bd195e17fc42))

## [3.8.3](https://github.com/cds-snc/forms-terraform/compare/v3.8.2...v3.8.3) (2024-04-22)


### Bug Fixes

* changed TTL field type from String to Number in ReliabilityQueue DynamoDB table ([#637](https://github.com/cds-snc/forms-terraform/issues/637)) ([868fa43](https://github.com/cds-snc/forms-terraform/commit/868fa435282ede065daf0b794c6b18602e59bc12))

## [3.8.2](https://github.com/cds-snc/forms-terraform/compare/v3.8.1...v3.8.2) (2024-04-18)


### Miscellaneous Chores

* **deps:** update all non-major docker images ([#500](https://github.com/cds-snc/forms-terraform/issues/500)) ([dc47785](https://github.com/cds-snc/forms-terraform/commit/dc477857612899c0c3e1df49856a6563a9d6706a))

## [3.8.1](https://github.com/cds-snc/forms-terraform/compare/v3.8.0...v3.8.1) (2024-04-16)


### Bug Fixes

* Do not try to handle non form types ([#631](https://github.com/cds-snc/forms-terraform/issues/631)) ([ea6b3fb](https://github.com/cds-snc/forms-terraform/commit/ea6b3fb4aadf4c92677d5998385c49509332d696))

## [3.8.0](https://github.com/cds-snc/forms-terraform/compare/v3.7.2...v3.8.0) (2024-04-16)


### Features

* deploy redis and postgresql in localstack ([#620](https://github.com/cds-snc/forms-terraform/issues/620)) ([20e0fc1](https://github.com/cds-snc/forms-terraform/commit/20e0fc12be3789102a537b8ea8217c8dd64b99fb))


### Bug Fixes

* Add missing component (combobox / searchable list) for email responses ([4cbd734](https://github.com/cds-snc/forms-terraform/commit/4cbd734700ca36f804e80ddc2bc4b6b0ca884efa))

## [3.7.2](https://github.com/cds-snc/forms-terraform/compare/v3.7.1...v3.7.2) (2024-03-26)


### Miscellaneous Chores

* synced file(s) with cds-snc/site-reliability-engineering ([#555](https://github.com/cds-snc/forms-terraform/issues/555)) ([bfd81fe](https://github.com/cds-snc/forms-terraform/commit/bfd81fef0c4875d16cd6a90f9b865fdcf8de67a4))
* synced file(s) with cds-snc/site-reliability-engineering ([#621](https://github.com/cds-snc/forms-terraform/issues/621)) ([dd097d1](https://github.com/cds-snc/forms-terraform/commit/dd097d1f5ef894b246cdd9be8cd1caf7100d2cea))

## [3.7.1](https://github.com/cds-snc/forms-terraform/compare/v3.7.0...v3.7.1) (2024-03-15)


### Bug Fixes

* async issue with lambda notification logic ([#616](https://github.com/cds-snc/forms-terraform/issues/616)) ([a344cc1](https://github.com/cds-snc/forms-terraform/commit/a344cc1483b9d3a75a808786bcb7bc38c833addc))
* the alarm monitoring for 'unhealthyhost' wasn't working properly ([#614](https://github.com/cds-snc/forms-terraform/issues/614)) ([4309971](https://github.com/cds-snc/forms-terraform/commit/43099710b7b06268c84440262b4ac12180defffb))


### Code Refactoring

* lambda that notifies slack and opsgenie ([#609](https://github.com/cds-snc/forms-terraform/issues/609)) ([ba562d3](https://github.com/cds-snc/forms-terraform/commit/ba562d3e790cdd39f4a8f94c19b418eae2e69de2))

## [3.7.0](https://github.com/cds-snc/forms-terraform/compare/v3.6.0...v3.7.0) (2024-02-29)


### Features

* enable file scanning on Vault S3 bucket ([#611](https://github.com/cds-snc/forms-terraform/issues/611)) ([a44318c](https://github.com/cds-snc/forms-terraform/commit/a44318ca35a03c7484fb82d6b29f615dffcd66a3))


### Bug Fixes

* cloudwatch alarm configuration for unhealthy host ([#604](https://github.com/cds-snc/forms-terraform/issues/604)) ([dbdbba1](https://github.com/cds-snc/forms-terraform/commit/dbdbba11c84a19d0ea521ba3bb341a2df4009c97))


### Miscellaneous Chores

* Rename next auth url in preperation for next auth upgrade ([f16e080](https://github.com/cds-snc/forms-terraform/commit/f16e080571b73e6f9800ae3ad69670fb93bf1701))

## [3.6.0](https://github.com/cds-snc/forms-terraform/compare/v3.5.2...v3.6.0) (2024-02-27)


### Features

* Audit Log Archiver ([e06658f](https://github.com/cds-snc/forms-terraform/commit/e06658fa580a6fd28768c0bf010a1c2447bf78b4))
* send critical/error events to OpsGenie ([#596](https://github.com/cds-snc/forms-terraform/issues/596)) ([1281b1c](https://github.com/cds-snc/forms-terraform/commit/1281b1c9c602150862ab64a8ccbd0720346039c9))


### Bug Fixes

* add a way of unit testing lambda quickly and fix the lowercase logical error ([#600](https://github.com/cds-snc/forms-terraform/issues/600)) ([4b733d7](https://github.com/cds-snc/forms-terraform/commit/4b733d79905dc103b1cd8cc3a6b7d0ad6bd45ad9))
* add missing subscription filter to audit logs archiver lambda logs ([#597](https://github.com/cds-snc/forms-terraform/issues/597)) ([0def180](https://github.com/cds-snc/forms-terraform/commit/0def180c743fc911db9f1b4ed64ee6051961c0dd))
* missing permissions for the audit logs archiver lambda to access S3 bucket ([#601](https://github.com/cds-snc/forms-terraform/issues/601)) ([05ce856](https://github.com/cds-snc/forms-terraform/commit/05ce8562238d9cf5052041154a03bff35f5c1e25))

## [3.5.2](https://github.com/cds-snc/forms-terraform/compare/v3.5.1...v3.5.2) (2024-02-08)


### Bug Fixes

* deployment issue due to audit logs TTL resource block that is not needed anymore ([#594](https://github.com/cds-snc/forms-terraform/issues/594)) ([9cd9098](https://github.com/cds-snc/forms-terraform/commit/9cd90985919521cd71ef3d4ef5c8bb4786ffeb21))
* nagware lambda trigger CRON definition is incorrect ([#595](https://github.com/cds-snc/forms-terraform/issues/595)) ([c7513ff](https://github.com/cds-snc/forms-terraform/commit/c7513ff45b58cb320bc51bdb8ce519fd4fe1dc2b))


### Miscellaneous Chores

* create env file that gets automatically loaded when we start the infra in Localstack ([#592](https://github.com/cds-snc/forms-terraform/issues/592)) ([b28c633](https://github.com/cds-snc/forms-terraform/commit/b28c63390802eeeaa92653a87842bde8010dbbb0))
* reduce number of Nagware emails and Slack notifications ([#591](https://github.com/cds-snc/forms-terraform/issues/591)) ([655061a](https://github.com/cds-snc/forms-terraform/commit/655061a1ef52b5708556a4a057162af605cb7071))

## [3.5.1](https://github.com/cds-snc/forms-terraform/compare/v3.5.0...v3.5.1) (2024-01-29)


### Bug Fixes

* ECS service autoscaling target ([#587](https://github.com/cds-snc/forms-terraform/issues/587)) ([fb3d104](https://github.com/cds-snc/forms-terraform/commit/fb3d104d08f7d39e1267b81c37781938e3b3979d))
* load test env vars and test file ([#588](https://github.com/cds-snc/forms-terraform/issues/588)) ([9748d19](https://github.com/cds-snc/forms-terraform/commit/9748d19a52527a8ea1bb605c1ec3c23f0a8d70d4))


### Miscellaneous Chores

* disable TTL for Audit logs DynamoDB table ([#589](https://github.com/cds-snc/forms-terraform/issues/589)) ([04ecac3](https://github.com/cds-snc/forms-terraform/commit/04ecac3f69a0f4231d3c60faea6fdc6004a6c9b9))
* remove production imports ([#585](https://github.com/cds-snc/forms-terraform/issues/585)) ([91b9278](https://github.com/cds-snc/forms-terraform/commit/91b9278bd1dd28adf4732c89933bdc215852563a))

## [3.5.0](https://github.com/cds-snc/forms-terraform/compare/v3.4.0...v3.5.0) (2024-01-25)


### Features

* add new cloudwatch alarm and waf rule for Cognito login outside Canada ([#558](https://github.com/cds-snc/forms-terraform/issues/558)) ([d23a252](https://github.com/cds-snc/forms-terraform/commit/d23a252ce155a95889cfb553237f5c33cbb88cd4))
* disable health check until maintenance mode implementation is finalized ([#538](https://github.com/cds-snc/forms-terraform/issues/538)) ([41c7d0a](https://github.com/cds-snc/forms-terraform/commit/41c7d0adc9c25c87445c22654e466e4f65a5520c))
* enable deletion protection on all DynamoDB tables ([#580](https://github.com/cds-snc/forms-terraform/issues/580)) ([62a00aa](https://github.com/cds-snc/forms-terraform/commit/62a00aa294ff34fcd110eb73f8b5c928f537b8b1))
* implement maintenance page design ([#544](https://github.com/cds-snc/forms-terraform/issues/544)) ([418b71a](https://github.com/cds-snc/forms-terraform/commit/418b71a131dfaa1e585057b8d3994cb832333ea0))
* OIDC roles for GitHub workflows ([#568](https://github.com/cds-snc/forms-terraform/issues/568)) ([3840ad9](https://github.com/cds-snc/forms-terraform/commit/3840ad9afa6e7843fd3784bb6994dd31c4f37899))
* redirect to static maintenance web page when in maintenance mode or service is down ([#530](https://github.com/cds-snc/forms-terraform/issues/530)) ([a99ccbe](https://github.com/cds-snc/forms-terraform/commit/a99ccbe4b5e286fe64d4cdb8a9b697386fb8ebfb))
* send notification on Slack when a timeout is detected in the lambda logs ([#581](https://github.com/cds-snc/forms-terraform/issues/581)) ([d200b33](https://github.com/cds-snc/forms-terraform/commit/d200b3336deb6c47f1f57f3e109d73414ab35e73))


### Bug Fixes

* acl not required with bucket ownership controls ([#570](https://github.com/cds-snc/forms-terraform/issues/570)) ([1e31ae7](https://github.com/cds-snc/forms-terraform/commit/1e31ae70915a6b289f7326bb05848ab052c3cca4))
* Check for localstack or AWS env ([#547](https://github.com/cds-snc/forms-terraform/issues/547)) ([f0e15b2](https://github.com/cds-snc/forms-terraform/commit/f0e15b2fa1ac815a73b9c597be489f2592994151))
* **deps:** update dependency axios to v1 [security] ([#531](https://github.com/cds-snc/forms-terraform/issues/531)) ([9860d8e](https://github.com/cds-snc/forms-terraform/commit/9860d8e603a90e14f3941bdcc0f7a1f7a90e001d))
* ecs force deployment option ([#573](https://github.com/cds-snc/forms-terraform/issues/573)) ([2d0e004](https://github.com/cds-snc/forms-terraform/commit/2d0e004f5bd2287dace2b94ae131db18cfe14052))
* enable code signing on Vault data integrity check lambda ([#548](https://github.com/cds-snc/forms-terraform/issues/548)) ([50e1edc](https://github.com/cds-snc/forms-terraform/commit/50e1edcac419b52d75ae5e902afb55b25b6c9539))
* GC Notify API Key is not properly passed to Nagware and Reliability lambdas ([#553](https://github.com/cds-snc/forms-terraform/issues/553)) ([0c9bfaa](https://github.com/cds-snc/forms-terraform/commit/0c9bfaa7edda59d57a62893ac41464f14c2519a4))
* GitHub workflow OIDC role claims ([#575](https://github.com/cds-snc/forms-terraform/issues/575)) ([bee2a0a](https://github.com/cds-snc/forms-terraform/commit/bee2a0afc63e64ce9126af1a8bf73e942ee7bf90))
* import pg package was not properly done in Nagware lambda ([#554](https://github.com/cds-snc/forms-terraform/issues/554)) ([58fdc66](https://github.com/cds-snc/forms-terraform/commit/58fdc6699e2d99fe7ff18b0c45a19a37bf932372))
* initialization of NotifyClient is not working because of the way we pass the API key ([#576](https://github.com/cds-snc/forms-terraform/issues/576)) ([bd1904e](https://github.com/cds-snc/forms-terraform/commit/bd1904e7e882fc9049d4f09612277dc1b025fe34))
* intergrity alarm ([#542](https://github.com/cds-snc/forms-terraform/issues/542)) ([7440068](https://github.com/cds-snc/forms-terraform/commit/744006881b7823586cecd42b58c9825de39812ae))
* maintenance mode deployment issue ([#533](https://github.com/cds-snc/forms-terraform/issues/533)) ([a0ff418](https://github.com/cds-snc/forms-terraform/commit/a0ff4188c60481cf83c55e09bd29a070ce465706))
* maintenance mode deployment issues second try ([#534](https://github.com/cds-snc/forms-terraform/issues/534)) ([35f59eb](https://github.com/cds-snc/forms-terraform/commit/35f59ebc78fe1c2653eec8ddc821538378508a38))
* maintenance mode WAF rules to allow for new page resources to be loaded ([#550](https://github.com/cds-snc/forms-terraform/issues/550)) ([98cbf18](https://github.com/cds-snc/forms-terraform/commit/98cbf18f4b2314be858885ea3d06d7b4d1beb8bd))
* Missed an S3 ACL on previous PR ([#572](https://github.com/cds-snc/forms-terraform/issues/572)) ([783c8bc](https://github.com/cds-snc/forms-terraform/commit/783c8bc6a63f40b458fbf4a458f332e2ea61164b))
* missing aliases in Cloudfront distribution ([#540](https://github.com/cds-snc/forms-terraform/issues/540)) ([6f95764](https://github.com/cds-snc/forms-terraform/commit/6f95764fa7ace9c49ef0892c8e9106d61564a5e7))
* missing provider in WAF regex pattern set ([#552](https://github.com/cds-snc/forms-terraform/issues/552)) ([44ddbad](https://github.com/cds-snc/forms-terraform/commit/44ddbad42e08db111d9170148adfa77b7704d339))
* missing provider in waf rule ([#537](https://github.com/cds-snc/forms-terraform/issues/537)) ([6926dc3](https://github.com/cds-snc/forms-terraform/commit/6926dc391e93f73a646d8ee0f64dee7219923679))
* missing WAF rule and certificate. Health check now targets load balancer DNS ([#535](https://github.com/cds-snc/forms-terraform/issues/535)) ([85b8ea5](https://github.com/cds-snc/forms-terraform/commit/85b8ea5eec4c1d1a2d0b6fb56292553e61f42eab))
* PR review OIDC role for VPC lambda deploys ([#578](https://github.com/cds-snc/forms-terraform/issues/578)) ([e4c8376](https://github.com/cds-snc/forms-terraform/commit/e4c8376b4be9764f7fa8871de5888c98693b58f4))
* revert certificate changes including ELB DNS ([#536](https://github.com/cds-snc/forms-terraform/issues/536)) ([a4e41a1](https://github.com/cds-snc/forms-terraform/commit/a4e41a13667d1300a4b3745857aaebeffce0f4cc))
* rework response archiver lambda ([#577](https://github.com/cds-snc/forms-terraform/issues/577)) ([e5da375](https://github.com/cds-snc/forms-terraform/commit/e5da375343e12f47398deeffaa5fced6bd599ffb))
* split Staging/Prod use of Scan Files service ([#569](https://github.com/cds-snc/forms-terraform/issues/569)) ([d043405](https://github.com/cds-snc/forms-terraform/commit/d04340553ecc02ff54dcb5b1d96d659276fa8f62))
* update Terragrunt mock values to fix TF plan ([#583](https://github.com/cds-snc/forms-terraform/issues/583)) ([26e4374](https://github.com/cds-snc/forms-terraform/commit/26e4374594907fee4e4f9e316a201ce1a56bd5c5))
* update to README file, adjust iterator age alarm threshold and fix to vault data integrity check local lambda test script ([#525](https://github.com/cds-snc/forms-terraform/issues/525)) ([0761ad0](https://github.com/cds-snc/forms-terraform/commit/0761ad05cc89bafa0739bf3443e79e84c959872a))
* WAF rule for maintenance mode not having proper scope ([#551](https://github.com/cds-snc/forms-terraform/issues/551)) ([f90bddc](https://github.com/cds-snc/forms-terraform/commit/f90bddcece444a85d77e507fb6e7f6cbd75f5d27))


### Miscellaneous Chores

* AWS Provider upgrade ([#556](https://github.com/cds-snc/forms-terraform/issues/556)) ([1d6273c](https://github.com/cds-snc/forms-terraform/commit/1d6273c1b2c01260adce7fb09055be348a6c124c))
* create production `import.tf` file ([#584](https://github.com/cds-snc/forms-terraform/issues/584)) ([9d3b92a](https://github.com/cds-snc/forms-terraform/commit/9d3b92a39236ae3516def0a0119df7cfbbe43369))
* created local '.github/workflows/backstage-catalog-helper.yml' from remote 'tools/sre_file_sync/backstage-catalog-helper.yml' ([#520](https://github.com/cds-snc/forms-terraform/issues/520)) ([c4f5f0d](https://github.com/cds-snc/forms-terraform/commit/c4f5f0d24b6265a0d9499d5c44037976fa490a3a))
* **deps:** update all non-major github action dependencies ([#512](https://github.com/cds-snc/forms-terraform/issues/512)) ([75bc194](https://github.com/cds-snc/forms-terraform/commit/75bc194e4192ac5dcb31a578f765f16722c792e8))
* reorganization of infrastructure as code for better local development ([#532](https://github.com/cds-snc/forms-terraform/issues/532)) ([6f84917](https://github.com/cds-snc/forms-terraform/commit/6f849171fd1eab91207a769e7cbb00ed7bb8ea0a))
* update email with sign off language rather than confirm language ([#541](https://github.com/cds-snc/forms-terraform/issues/541)) ([64158be](https://github.com/cds-snc/forms-terraform/commit/64158be13e27e9f1bef1e540a8642048171c72dc))
* Update README.md ([#506](https://github.com/cds-snc/forms-terraform/issues/506)) ([00ee9ca](https://github.com/cds-snc/forms-terraform/commit/00ee9ca6126fac2753b1d6ad87f52d080cfabdf8))

## [3.4.0](https://github.com/cds-snc/forms-terraform/compare/v3.3.1...v3.4.0) (2023-10-25)


### Features

* addition of canada.ca domain ([#515](https://github.com/cds-snc/forms-terraform/issues/515)) ([9c32551](https://github.com/cds-snc/forms-terraform/commit/9c3255128de31d0a9665d41078a93604cbba0f9d))


### Bug Fixes

* ACM cert not being recreated on domain name addition ([#518](https://github.com/cds-snc/forms-terraform/issues/518)) ([2ba215d](https://github.com/cds-snc/forms-terraform/commit/2ba215d4750037d9d7993e6dff4bd76283b621f6))
* handle duplicate log events ([#511](https://github.com/cds-snc/forms-terraform/issues/511)) ([e8de8d6](https://github.com/cds-snc/forms-terraform/commit/e8de8d6a02a900fedde274c3de3f8f8d19818882))
* site verification files allowed path were not properly included in regex ([#510](https://github.com/cds-snc/forms-terraform/issues/510)) ([30a9c8b](https://github.com/cds-snc/forms-terraform/commit/30a9c8bc7c9dacf6d05be80a03ae1d661abb7fc2))
* temporarily remove additional domain names ([#519](https://github.com/cds-snc/forms-terraform/issues/519)) ([5e5a50f](https://github.com/cds-snc/forms-terraform/commit/5e5a50f6fa6e13a6d7babe48df10d7ccce58b8a8))


### Miscellaneous Chores

* allow path to verification files for search engines tool ([#509](https://github.com/cds-snc/forms-terraform/issues/509)) ([2fba19c](https://github.com/cds-snc/forms-terraform/commit/2fba19c6fa2cbd374735986e0aa6ca17b8ea1f70))
* **deps:** update all non-major github action dependencies ([#501](https://github.com/cds-snc/forms-terraform/issues/501)) ([c9c3b84](https://github.com/cds-snc/forms-terraform/commit/c9c3b84684ad894e52186ae706b026f0eb9dae01))
* synced file(s) with cds-snc/site-reliability-engineering ([#508](https://github.com/cds-snc/forms-terraform/issues/508)) ([14f249d](https://github.com/cds-snc/forms-terraform/commit/14f249d508d35c5d22302454d95093aecc22a38c))

## [3.3.1](https://github.com/cds-snc/forms-terraform/compare/v3.3.0...v3.3.1) (2023-09-25)


### Miscellaneous Chores

* Add release manifest code owners ([#499](https://github.com/cds-snc/forms-terraform/issues/499)) ([d63e8a2](https://github.com/cds-snc/forms-terraform/commit/d63e8a22a174119248bb33728d006aba5c456426))
* synced file(s) with cds-snc/site-reliability-engineering ([#498](https://github.com/cds-snc/forms-terraform/issues/498)) ([9a93c2f](https://github.com/cds-snc/forms-terraform/commit/9a93c2f70ba3dffa206e53a977aa36219d147e04))

## [3.3.0](https://github.com/cds-snc/forms-terraform/compare/v3.2.1...v3.3.0) (2023-09-19)


### Features

* Add freskdesk API key ([d038c81](https://github.com/cds-snc/forms-terraform/commit/d038c81cff37bbe814bb08539ceb520dad5f93f6))
* notify Slack if Terraform apply fails ([#485](https://github.com/cds-snc/forms-terraform/issues/485)) ([45487c7](https://github.com/cds-snc/forms-terraform/commit/45487c76ff3d415fc587f6964adfe02df7cde3ea))


### Bug Fixes

* Add missing freshdesk api key to ecs task ([d8a96ac](https://github.com/cds-snc/forms-terraform/commit/d8a96acdc8d5b5c02b04c65a8cbde10df80f2fcd))
* format of TF workflow Slack webhook URL ([#496](https://github.com/cds-snc/forms-terraform/issues/496)) ([4bb5ca2](https://github.com/cds-snc/forms-terraform/commit/4bb5ca28a715635cfc6226255a5ff31f654531e6))
* Github action logic for release-generator ([#479](https://github.com/cds-snc/forms-terraform/issues/479)) ([dbb3a77](https://github.com/cds-snc/forms-terraform/commit/dbb3a777ca4f8955e01bac19487787732c81847e))
* IAM permission for freshdesk secret ([f22ee82](https://github.com/cds-snc/forms-terraform/commit/f22ee828ee9dfcd25c89e441ef6e4699c1ce92c1))
* release generator token step ([#495](https://github.com/cds-snc/forms-terraform/issues/495)) ([ae47a64](https://github.com/cds-snc/forms-terraform/commit/ae47a64aa5c306ff7ceea94b2b457591f605eeef))
* set target Slack channel for notification ([#487](https://github.com/cds-snc/forms-terraform/issues/487)) ([fee609c](https://github.com/cds-snc/forms-terraform/commit/fee609c764697c166d2782af63f7fc463e55b4de))


### Miscellaneous Chores

* **deps:** lock file maintenance ([#467](https://github.com/cds-snc/forms-terraform/issues/467)) ([d9329d5](https://github.com/cds-snc/forms-terraform/commit/d9329d54dc698df1c333c98d35b90a4f5d1ef297))
* **deps:** update all non-major docker images ([#465](https://github.com/cds-snc/forms-terraform/issues/465)) ([1766d88](https://github.com/cds-snc/forms-terraform/commit/1766d88be28d308995d75748714c924786d7aa77))
* **deps:** update all non-major docker images ([#488](https://github.com/cds-snc/forms-terraform/issues/488)) ([1e3d5c3](https://github.com/cds-snc/forms-terraform/commit/1e3d5c3991a9e30e5efb34b9e5bf194354fd075b))
* **deps:** update all non-major github action dependencies ([#466](https://github.com/cds-snc/forms-terraform/issues/466)) ([38611b1](https://github.com/cds-snc/forms-terraform/commit/38611b19818ec546ef48bae048126b17475963b2))
* **deps:** update all non-major github action dependencies ([#472](https://github.com/cds-snc/forms-terraform/issues/472)) ([fb2c43c](https://github.com/cds-snc/forms-terraform/commit/fb2c43cfa4ae93e5fb7d7672e1ea3f9c8ca76c6c))
* **deps:** update aws-actions/configure-aws-credentials digest to fbaaea8 ([#489](https://github.com/cds-snc/forms-terraform/issues/489)) ([f0f7f6b](https://github.com/cds-snc/forms-terraform/commit/f0f7f6bbea8ac408673403fddc9c7b33cc6aec46))
* release generator ([#475](https://github.com/cds-snc/forms-terraform/issues/475)) ([31e1b98](https://github.com/cds-snc/forms-terraform/commit/31e1b98729488e5e594bc77d0f180521a516b62c))
* release generator fix ([#484](https://github.com/cds-snc/forms-terraform/issues/484)) ([661cf9a](https://github.com/cds-snc/forms-terraform/commit/661cf9a1f7aaf1bb3a8f9de0f05a680185ebb8e4))
* synced file(s) with cds-snc/site-reliability-engineering ([#468](https://github.com/cds-snc/forms-terraform/issues/468)) ([563f2af](https://github.com/cds-snc/forms-terraform/commit/563f2afb069b06c793914c1f2efef72eda23436b))
* synced file(s) with cds-snc/site-reliability-engineering ([#490](https://github.com/cds-snc/forms-terraform/issues/490)) ([74cc135](https://github.com/cds-snc/forms-terraform/commit/74cc135e2233e3e6a663c60e7e3e01c1da0afd16))
* synced local '.github/workflows/ossf-scorecard.yml' with remote 'tools/sre_file_sync/ossf-scorecard.yml' ([#470](https://github.com/cds-snc/forms-terraform/issues/470)) ([4565dcf](https://github.com/cds-snc/forms-terraform/commit/4565dcf1af1f905f3940f5a3f0148bfc23e81161))
* synced local '.github/workflows/ossf-scorecard.yml' with remote 'tools/sre_file_sync/ossf-scorecard.yml' ([#486](https://github.com/cds-snc/forms-terraform/issues/486)) ([8b3eee3](https://github.com/cds-snc/forms-terraform/commit/8b3eee37ae163b5671dae8b4f6603307cc83976f))
* upgrade python image ([#471](https://github.com/cds-snc/forms-terraform/issues/471)) ([e75ef9b](https://github.com/cds-snc/forms-terraform/commit/e75ef9ba9805001bf956f0bf3beca3a872777ff4))
* use GitHub app token with release-please ([#491](https://github.com/cds-snc/forms-terraform/issues/491)) ([92f10eb](https://github.com/cds-snc/forms-terraform/commit/92f10eb282cf3ad3f3345b61e05f840210f5394a))


### Code Refactoring

* split out security group rules from inline ([6eaee25](https://github.com/cds-snc/forms-terraform/commit/6eaee251077a2706c83009e32eb8a96ce968f08a))
