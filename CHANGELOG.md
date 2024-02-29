# Changelog

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
