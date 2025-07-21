# Changelog

## [3.37.0](https://github.com/cds-snc/forms-terraform/compare/v3.36.0...v3.37.0) (2025-07-09)


### Features

* add submit-form-server-action-id in AWS System manager for load testing lambda function ([#1052](https://github.com/cds-snc/forms-terraform/issues/1052)) ([c5e150f](https://github.com/cds-snc/forms-terraform/commit/c5e150f5678d7d530c15948abdb984ac0ea509df))
* load test code improvements ([#1057](https://github.com/cds-snc/forms-terraform/issues/1057)) ([0c45278](https://github.com/cds-snc/forms-terraform/commit/0c4527883b4737ffb53bb41306cddec4ea678c9e))
* load testing submission attachments API ([#1051](https://github.com/cds-snc/forms-terraform/issues/1051)) ([0e982d1](https://github.com/cds-snc/forms-terraform/commit/0e982d1007e04cd5c653eddfdd13cf8f2c9e03af))
* output percentiles once load test has completed ([#1055](https://github.com/cds-snc/forms-terraform/issues/1055)) ([e20d044](https://github.com/cds-snc/forms-terraform/commit/e20d044be4963a5740d7206dc3d1edb29f96eee7))


### Bug Fixes

* add missing lambda context information to load test lambda output ([#1054](https://github.com/cds-snc/forms-terraform/issues/1054)) ([f5e0451](https://github.com/cds-snc/forms-terraform/commit/f5e0451aaecb25409f7362d7738dd97834b39023))
* return JSON string with load testing results ([#1053](https://github.com/cds-snc/forms-terraform/issues/1053)) ([f4b22d0](https://github.com/cds-snc/forms-terraform/commit/f4b22d07d1c6188c24c6ea45d0f964a14aaae6f0))
* rework load test lambda payload to comply with Invokust library ([#1060](https://github.com/cds-snc/forms-terraform/issues/1060)) ([97f4f9e](https://github.com/cds-snc/forms-terraform/commit/97f4f9e66ea6340eb5bb480a61dd20a82cdca907))


### Miscellaneous Chores

* **deps:** update all non-major github action dependencies ([#907](https://github.com/cds-snc/forms-terraform/issues/907)) ([92d8bb8](https://github.com/cds-snc/forms-terraform/commit/92d8bb86d4331067aceeda87df7e2d99a8827442))
* **deps:** update vitest monorepo to v3 (major) ([#877](https://github.com/cds-snc/forms-terraform/issues/877)) ([98f77c0](https://github.com/cds-snc/forms-terraform/commit/98f77c0ebad4fabe08af9c0e4ca0db1ca111fff1))
* synced file(s) with cds-snc/site-reliability-engineering ([#1048](https://github.com/cds-snc/forms-terraform/issues/1048)) ([f44754d](https://github.com/cds-snc/forms-terraform/commit/f44754d2bdfc4780b438834c55c0785fe9d07c2b))


### Code Refactoring

* instantiate clients outside of functions ([#1058](https://github.com/cds-snc/forms-terraform/issues/1058)) ([201bd45](https://github.com/cds-snc/forms-terraform/commit/201bd452675e342e6e7c569a691353a2a05163d1))

## [3.36.0](https://github.com/cds-snc/forms-terraform/compare/v3.35.0...v3.36.0) (2025-06-21)


### Features

* add new submission attachments property to Vault ([#1045](https://github.com/cds-snc/forms-terraform/issues/1045)) ([3715727](https://github.com/cds-snc/forms-terraform/commit/37157279841d28506547f5427dec8ca88b086fc7))
* restrict HTTP/1 access to IdP to limited number of paths ([#1035](https://github.com/cds-snc/forms-terraform/issues/1035)) ([2b98379](https://github.com/cds-snc/forms-terraform/commit/2b9837973aebf16e8708d366e99c5389febb5d44))
* submission attachments support for the API ([#1044](https://github.com/cds-snc/forms-terraform/issues/1044)) ([2cb55a8](https://github.com/cds-snc/forms-terraform/commit/2cb55a8a5d8f4756d30d360d5709d9dcc7111484))


### Bug Fixes

* formatting in guard_duty file ([#1047](https://github.com/cds-snc/forms-terraform/issues/1047)) ([0fd3c41](https://github.com/cds-snc/forms-terraform/commit/0fd3c41ddfe56aaaf9ba9e9fd1d090fc20f87f4b))


### Miscellaneous Chores

* Change file scanning engine and change SQS queue types ([#1043](https://github.com/cds-snc/forms-terraform/issues/1043)) ([b8ff37a](https://github.com/cds-snc/forms-terraform/commit/b8ff37a9d00c0798a59253f18aa0b5080b3c806d))
* **deps:** update dependency cryptography to v44 [security] ([#946](https://github.com/cds-snc/forms-terraform/issues/946)) ([a8cfcf1](https://github.com/cds-snc/forms-terraform/commit/a8cfcf1454be2e5169fdf72f4d3b546272c3567a))
* remove unnecessary environment variables ([#1036](https://github.com/cds-snc/forms-terraform/issues/1036)) ([579ceef](https://github.com/cds-snc/forms-terraform/commit/579ceef4588bcc0b43f6f9d7add73e085c6aa92e))
* set reliability lambda concurrency to 150 ([#1041](https://github.com/cds-snc/forms-terraform/issues/1041)) ([dac07b1](https://github.com/cds-snc/forms-terraform/commit/dac07b17f9aed7fa3b14b1f1a548ee9119393b26))
* synced file(s) with cds-snc/site-reliability-engineering ([#924](https://github.com/cds-snc/forms-terraform/issues/924)) ([ae6fffd](https://github.com/cds-snc/forms-terraform/commit/ae6fffd45c6535c3f38124cdcb062224457d7677))

## [3.35.0](https://github.com/cds-snc/forms-terraform/compare/v3.34.0...v3.35.0) (2025-05-30)


### Features

* enable communication between Web App and IdP through PR review environment ([#1039](https://github.com/cds-snc/forms-terraform/issues/1039)) ([a5334b3](https://github.com/cds-snc/forms-terraform/commit/a5334b3abf866963a54c2b0864292faaef9f5003))


### Miscellaneous Chores

* Update API WAF allowed URL paths ([#1040](https://github.com/cds-snc/forms-terraform/issues/1040)) ([08a071d](https://github.com/cds-snc/forms-terraform/commit/08a071debcde3b4487c30fd97272f25e3b21bad3))
* update submission id for response download ([#1032](https://github.com/cds-snc/forms-terraform/issues/1032)) ([371d49c](https://github.com/cds-snc/forms-terraform/commit/371d49c6fc7d7f1f83de3ad6e87fc1bad9e2c0e5))

## [3.34.0](https://github.com/cds-snc/forms-terraform/compare/v3.33.1...v3.34.0) (2025-05-27)


### Features

* adds new environment variables to the API ECS task for new API build in order to enable local communication with Zitadel ([#1024](https://github.com/cds-snc/forms-terraform/issues/1024)) ([370af93](https://github.com/cds-snc/forms-terraform/commit/370af93665a8499bdb995f5239febd4aa8c1b07f))
* enables local communication between Web app and Zitadel ([#1034](https://github.com/cds-snc/forms-terraform/issues/1034)) ([99b9ee3](https://github.com/cds-snc/forms-terraform/commit/99b9ee310fb72d472fd4a607f903b617353524c3))


### Bug Fixes

* API end to end test does not need custom httpAgent to bypass TLS certificate verification ([#1023](https://github.com/cds-snc/forms-terraform/issues/1023)) ([9be405c](https://github.com/cds-snc/forms-terraform/commit/9be405c8d32eab37e457c4731e9ad4a3483ab119))
* opens local communication between API and IdP through security groups ([#1025](https://github.com/cds-snc/forms-terraform/issues/1025)) ([e226349](https://github.com/cds-snc/forms-terraform/commit/e226349dbf6d238ebdd6140341861e595874131d))
* WAF ignore 404 from LB and Dynamic IP Rule ([#1037](https://github.com/cds-snc/forms-terraform/issues/1037)) ([3753660](https://github.com/cds-snc/forms-terraform/commit/3753660ccbe931b368afb547c420b5059f8e28c9))


### Miscellaneous Chores

* change from debug to info level for Zitadel ([#1030](https://github.com/cds-snc/forms-terraform/issues/1030)) ([b2ceedc](https://github.com/cds-snc/forms-terraform/commit/b2ceedc0f59c91a24b4d8846b27c5d0558c27862))
* Change log level to debug and enable Notifcation worker ([#1029](https://github.com/cds-snc/forms-terraform/issues/1029)) ([06b57a8](https://github.com/cds-snc/forms-terraform/commit/06b57a829e39f686c1b082ef00612746890a5b7b))
* disable Zitadel TLS traffic enforcement ([#1022](https://github.com/cds-snc/forms-terraform/issues/1022)) ([b9cacfa](https://github.com/cds-snc/forms-terraform/commit/b9cacfa6dbbb540a5c9fb791f5e55f7200df2dcd))
* Enable file scanning for local development ([#1031](https://github.com/cds-snc/forms-terraform/issues/1031)) ([606b1d3](https://github.com/cds-snc/forms-terraform/commit/606b1d3aa919aa7aae6be50814c77597804d2892))
* increase API end to end test frequency ([#1021](https://github.com/cds-snc/forms-terraform/issues/1021)) ([37ccbe0](https://github.com/cds-snc/forms-terraform/commit/37ccbe08f8f8b223145287c402a70e944ab089d9))
* Modify github release to hold back zitadel update ([#1033](https://github.com/cds-snc/forms-terraform/issues/1033)) ([aea4b59](https://github.com/cds-snc/forms-terraform/commit/aea4b5978cdb751726d7ead7519da3a81e750dbb))
* Tweak to IDP database connection config ([#1026](https://github.com/cds-snc/forms-terraform/issues/1026)) ([9bd7908](https://github.com/cds-snc/forms-terraform/commit/9bd790841a5ed5cbef4e6a4397342f6787100384))
* update all lambdas ([#1019](https://github.com/cds-snc/forms-terraform/issues/1019)) ([5346a33](https://github.com/cds-snc/forms-terraform/commit/5346a336d5b2a929c29ee89d60d7d539ee5e65e7))
* upgrade zitadel image to 3.0.4 ([#1016](https://github.com/cds-snc/forms-terraform/issues/1016)) ([7a88ad3](https://github.com/cds-snc/forms-terraform/commit/7a88ad360d41b16c602a403ad46739130c39e9b6))
* Zitadel config ([#1027](https://github.com/cds-snc/forms-terraform/issues/1027)) ([290a021](https://github.com/cds-snc/forms-terraform/commit/290a021341ba933a092389d0289f244b8272566c))
* Zitadel switch to legacy for notifications ([#1028](https://github.com/cds-snc/forms-terraform/issues/1028)) ([aeaa07e](https://github.com/cds-snc/forms-terraform/commit/aeaa07e045906ee75a61c751b6c5ae2f072bf339))

## [3.33.1](https://github.com/cds-snc/forms-terraform/compare/v3.33.0...v3.33.1) (2025-05-13)


### Bug Fixes

* add api end to end test lambda to list of production lambdas ([#1017](https://github.com/cds-snc/forms-terraform/issues/1017)) ([02d4be3](https://github.com/cds-snc/forms-terraform/commit/02d4be396a4f2e69fdedd2e048207295f58cc930))

## [3.33.0](https://github.com/cds-snc/forms-terraform/compare/v3.32.1...v3.33.0) (2025-05-12)


### Features

* API end to end test ([#1004](https://github.com/cds-snc/forms-terraform/issues/1004)) ([b815a45](https://github.com/cds-snc/forms-terraform/commit/b815a4575e736b06796dfc1086aa70c900337945))


### Bug Fixes

* API end to end test NodeJS app + container was not properly built ([#1011](https://github.com/cds-snc/forms-terraform/issues/1011)) ([075d928](https://github.com/cds-snc/forms-terraform/commit/075d9282975968d19e29d2f2f6261e881d45fc79))
* api end to end test security group can egress to the whole internet ([#1015](https://github.com/cds-snc/forms-terraform/issues/1015)) ([6c23ba5](https://github.com/cds-snc/forms-terraform/commit/6c23ba56077060f749d92bf3da0e5352cb58ca56))
* API end to end test security group is missing connection with private link one ([#1014](https://github.com/cds-snc/forms-terraform/issues/1014)) ([2bcde35](https://github.com/cds-snc/forms-terraform/commit/2bcde35517747fb4c38009f478530470e75e6f1e))
* aurora postgresql version for IdP RDS cluster ([#1013](https://github.com/cds-snc/forms-terraform/issues/1013)) ([62a3ba4](https://github.com/cds-snc/forms-terraform/commit/62a3ba4e15b9595ad2f3b11b3c4b3e6f29a3409d))
* local communication issues between API end to end test lambda and IdP + API services ([#1012](https://github.com/cds-snc/forms-terraform/issues/1012)) ([23ac1d4](https://github.com/cds-snc/forms-terraform/commit/23ac1d475d82a9089eb4c359b1b3441b8862c674))
* missing service discovery resource in development mode ([#1010](https://github.com/cds-snc/forms-terraform/issues/1010)) ([466f79b](https://github.com/cds-snc/forms-terraform/commit/466f79b9bb2b8034a3bf11706b064a9139f665d9))


### Miscellaneous Chores

* Add index for subject tracing ([#1007](https://github.com/cds-snc/forms-terraform/issues/1007)) ([643d7a6](https://github.com/cds-snc/forms-terraform/commit/643d7a6950c21ef3a64990a595d658a1cf9d2afe))

## [3.32.1](https://github.com/cds-snc/forms-terraform/compare/v3.32.0...v3.32.1) (2025-05-06)


### Bug Fixes

* aurora postgresql version ([#1005](https://github.com/cds-snc/forms-terraform/issues/1005)) ([693eff5](https://github.com/cds-snc/forms-terraform/commit/693eff5cda8d0b50cfd0774dcf1974a7ce4dbdee))

## [3.32.0](https://github.com/cds-snc/forms-terraform/compare/v3.31.0...v3.32.0) (2025-05-01)


### Features

* bump healthy host count alarm to SEV1 ([#992](https://github.com/cds-snc/forms-terraform/issues/992)) ([f2a1249](https://github.com/cds-snc/forms-terraform/commit/f2a1249d42974f079df10c883ccf2ca445e2b1e7))


### Bug Fixes

* both unsupported browser and javascript disabled pages are blocked by WAF because of missing HTML extension ([#1000](https://github.com/cds-snc/forms-terraform/issues/1000)) ([a7b8f70](https://github.com/cds-snc/forms-terraform/commit/a7b8f70eb1fcba45c5832245b1bbd584a832c5e3))


### Miscellaneous Chores

* Allow ECS task to access Audit Logs for APP and API ([#1003](https://github.com/cds-snc/forms-terraform/issues/1003)) ([d8f6909](https://github.com/cds-snc/forms-terraform/commit/d8f6909bc7ba65113accddd52a2dfa0ae336ae89))
* switch to CDS Release Bot ([#1002](https://github.com/cds-snc/forms-terraform/issues/1002)) ([0a1062d](https://github.com/cds-snc/forms-terraform/commit/0a1062d055334f5322aaec7134b09f9e2cada642))

## [3.31.0](https://github.com/cds-snc/forms-terraform/compare/v3.30.2...v3.31.0) (2025-04-24)


### Features

* replaced out of country alarm by WAF header injection for detection within the web application ([#996](https://github.com/cds-snc/forms-terraform/issues/996)) ([b056fac](https://github.com/cds-snc/forms-terraform/commit/b056fac26ae40e7ec92acbbf2c45ef82eaa3f124))


### Bug Fixes

* add missing Scan permission on DynamoDB for the API service ([#999](https://github.com/cds-snc/forms-terraform/issues/999)) ([7957d7f](https://github.com/cds-snc/forms-terraform/commit/7957d7ffd27165f8fcbc55eda04049f77be2bfd4))


### Miscellaneous Chores

* forward request to /debug/ready endpoint to IdP HTTP 1 target group ([#991](https://github.com/cds-snc/forms-terraform/issues/991)) ([d5415d2](https://github.com/cds-snc/forms-terraform/commit/d5415d2623ed82b72458f642c9911deff43a28b5))
* Nagware lambda use a single Postgres connector instance ([#998](https://github.com/cds-snc/forms-terraform/issues/998)) ([199d30d](https://github.com/cds-snc/forms-terraform/commit/199d30d14644ca0fa28a81d54b8a0816a9034e15))

## [3.30.2](https://github.com/cds-snc/forms-terraform/compare/v3.30.1...v3.30.2) (2025-04-23)


### Bug Fixes

* Submission Cron Job / Pagination & Ability to Publish Status for Users ([#994](https://github.com/cds-snc/forms-terraform/issues/994)) ([835042c](https://github.com/cds-snc/forms-terraform/commit/835042c5b1a0575a319180145580ca1cf2eecc95))


### Documentation

* Update docs for datalake. ([#988](https://github.com/cds-snc/forms-terraform/issues/988)) ([3467115](https://github.com/cds-snc/forms-terraform/commit/34671154f8ff488e9ff6a3cfa8e09701c3e9673c))

## [3.30.1](https://github.com/cds-snc/forms-terraform/compare/v3.30.0...v3.30.1) (2025-04-14)


### Bug Fixes

* Add a mode toggle for submissions so it can just be done easy peasy. ([#989](https://github.com/cds-snc/forms-terraform/issues/989)) ([6aca153](https://github.com/cds-snc/forms-terraform/commit/6aca153aeb638698d00fbd8fbe41672a2da24c64))


### Miscellaneous Chores

* disable Nagware Slack notifications ([#990](https://github.com/cds-snc/forms-terraform/issues/990)) ([94687e2](https://github.com/cds-snc/forms-terraform/commit/94687e2697d3c3c896eb269f0e9fa22852027d34))
* update connectors package to version 2.0.2 in order to pull Axios 1.8.4 update ([#986](https://github.com/cds-snc/forms-terraform/issues/986)) ([fa5e4dc](https://github.com/cds-snc/forms-terraform/commit/fa5e4dc096cf628d76f8db27518b8d158d838674))

## [3.30.0](https://github.com/cds-snc/forms-terraform/compare/v3.29.0...v3.30.0) (2025-04-07)


### Features

* Add Submissions from cloudwatch to Data Lake ([#978](https://github.com/cds-snc/forms-terraform/issues/978)) ([05bd7d3](https://github.com/cds-snc/forms-terraform/commit/05bd7d3fd635ee65579575993169f38df0f8bda2))
* Create new oidc roles for github actions ([#981](https://github.com/cds-snc/forms-terraform/issues/981)) ([03ba5a6](https://github.com/cds-snc/forms-terraform/commit/03ba5a6fc794e40431ab1bd471004a705c8f3b5a))
* create PR review/Rainbow environment shared resources ([#977](https://github.com/cds-snc/forms-terraform/issues/977)) ([24cdcac](https://github.com/cds-snc/forms-terraform/commit/24cdcac1ef3c2f697dded673140514d1e861af82))
* destroy PR review environment resources that will be shared with Rainbow deployment feature ([#976](https://github.com/cds-snc/forms-terraform/issues/976)) ([fdc8665](https://github.com/cds-snc/forms-terraform/commit/fdc8665b23c5acaf30bbf94d46b7af6eecb99a34))
* enable data lake replication from production ([#980](https://github.com/cds-snc/forms-terraform/issues/980)) ([e6bb913](https://github.com/cds-snc/forms-terraform/commit/e6bb9133f99876de419ddff02d3e159b7163d0c7))
* forms app legacy ECR ([#957](https://github.com/cds-snc/forms-terraform/issues/957)) ([6a3a79a](https://github.com/cds-snc/forms-terraform/commit/6a3a79ab86445726cb01496a0a29619f0f54f353))
* Lambda prisma migration ([#962](https://github.com/cds-snc/forms-terraform/issues/962)) ([3d8a504](https://github.com/cds-snc/forms-terraform/commit/3d8a504aef92b1a85b51d6c238c0710eeaf14a4f))
* Local development using scratch accounts ([#958](https://github.com/cds-snc/forms-terraform/issues/958)) ([40a9919](https://github.com/cds-snc/forms-terraform/commit/40a99195ad8a6bd7fa6510df9775c5e6360f41fb))
* rainbow deployment ([#961](https://github.com/cds-snc/forms-terraform/issues/961)) ([132246a](https://github.com/cds-snc/forms-terraform/commit/132246a1a8c06f8005999781dab4c8de0faf3c52))
* sso login script ([#964](https://github.com/cds-snc/forms-terraform/issues/964)) ([2697bba](https://github.com/cds-snc/forms-terraform/commit/2697bbac5aa8008ccc92971d06a105a50ac76bb5))


### Bug Fixes

* add back auto-approve ([#973](https://github.com/cds-snc/forms-terraform/issues/973)) ([a25e994](https://github.com/cds-snc/forms-terraform/commit/a25e994b65d7f5cef235189fbeffe73c8082e9e4))
* add lambda get function to prisma role ([#983](https://github.com/cds-snc/forms-terraform/issues/983)) ([7b40983](https://github.com/cds-snc/forms-terraform/commit/7b4098315ed92d9d80c92124ed4391fd94861bcc))
* add prisma lambda to filter for build ([#963](https://github.com/cds-snc/forms-terraform/issues/963)) ([ff27fa2](https://github.com/cds-snc/forms-terraform/commit/ff27fa28879b3dd6204432251db475c6e0827522))
* Boost lambda memory ([#984](https://github.com/cds-snc/forms-terraform/issues/984)) ([1d56c40](https://github.com/cds-snc/forms-terraform/commit/1d56c400a05872d7fcd1c3496cbe488f1f289dfe))
* missing permissions to copy S3 object with tags ([#966](https://github.com/cds-snc/forms-terraform/issues/966)) ([997e577](https://github.com/cds-snc/forms-terraform/commit/997e5775bfe53033505af563b4071c3d6018db6a))
* remove old terragrunt flag ([#969](https://github.com/cds-snc/forms-terraform/issues/969)) ([67c718a](https://github.com/cds-snc/forms-terraform/commit/67c718ad2b6117e78580cf06e4435267c4a3935a))
* revert localstack detection when initializing Postgres connector ([#956](https://github.com/cds-snc/forms-terraform/issues/956)) ([5cd34ff](https://github.com/cds-snc/forms-terraform/commit/5cd34ffa3f1b39f38489cb1fece76b7d15e4cc1c))
* skip lambda IAM role creation in scratch account ([#979](https://github.com/cds-snc/forms-terraform/issues/979)) ([6ea93b9](https://github.com/cds-snc/forms-terraform/commit/6ea93b9be09ee9dbfd5c3788792c4fee7ec79426))
* update connect_env to use latest tf and tg version ([#968](https://github.com/cds-snc/forms-terraform/issues/968)) ([710fa86](https://github.com/cds-snc/forms-terraform/commit/710fa86bb2e63d6231ce64b800b72c87b38e39f4))


### Miscellaneous Chores

* add timers to run scripts ([#965](https://github.com/cds-snc/forms-terraform/issues/965)) ([5d95785](https://github.com/cds-snc/forms-terraform/commit/5d95785f7d9ba15dcc7f7461d040da9108fc44a3))
* bump connectors package from v1 to v2 ([#985](https://github.com/cds-snc/forms-terraform/issues/985)) ([84eba3c](https://github.com/cds-snc/forms-terraform/commit/84eba3ce0cd43ea3ae9d41c71993a9ee47152e13))
* hcaptcha prod ([#959](https://github.com/cds-snc/forms-terraform/issues/959)) ([07f6b83](https://github.com/cds-snc/forms-terraform/commit/07f6b83d023cf0ee13cbbf28ebc85a05c0efda88))
* re-enable Staging data replication to Data Lake ([#974](https://github.com/cds-snc/forms-terraform/issues/974)) ([965e67c](https://github.com/cds-snc/forms-terraform/commit/965e67ce4081d521e0c48852fab20f019ac6a453))
* reduce the number of oidc roles created ([#982](https://github.com/cds-snc/forms-terraform/issues/982)) ([8f6e24a](https://github.com/cds-snc/forms-terraform/commit/8f6e24a74e6f937578863126c3304a90bd6f017d))
* script clean up ([#970](https://github.com/cds-snc/forms-terraform/issues/970)) ([5ebe30a](https://github.com/cds-snc/forms-terraform/commit/5ebe30a12894869bc63dafb033b998a59a052e56))
* speed up launch of dev environment ([#967](https://github.com/cds-snc/forms-terraform/issues/967)) ([c1b4919](https://github.com/cds-snc/forms-terraform/commit/c1b4919e9882b343e89a2ff95b1529ccfccb0111))


### Code Refactoring

* leverage new connectors package ([#953](https://github.com/cds-snc/forms-terraform/issues/953)) ([570a7e0](https://github.com/cds-snc/forms-terraform/commit/570a7e027813529cad34938a8db8c93893ec9952))

## [3.29.0](https://github.com/cds-snc/forms-terraform/compare/v3.28.0...v3.29.0) (2025-02-13)


### Features

* Add cross acount policy for ECR in Staging only ([#943](https://github.com/cds-snc/forms-terraform/issues/943)) ([f026963](https://github.com/cds-snc/forms-terraform/commit/f0269635fe44efe62da950e59afab9773d5efcf3))
* add S3 replicate rule to Platform data lake ([#944](https://github.com/cds-snc/forms-terraform/issues/944)) ([a0b34ef](https://github.com/cds-snc/forms-terraform/commit/a0b34ef9ed90e2f8f74c4ce768a10925fd3c7863))
* ecr policy to allow cross acoutn sharing ([#948](https://github.com/cds-snc/forms-terraform/issues/948)) ([b7a810b](https://github.com/cds-snc/forms-terraform/commit/b7a810b31652910b8b5399025d1bed6136afe2bf))
* replicate prod data to the Platform data lake ([#950](https://github.com/cds-snc/forms-terraform/issues/950)) ([b4d0d95](https://github.com/cds-snc/forms-terraform/commit/b4d0d954e86a2315cb7c6f4bc5eb55c22113f056))


### Bug Fixes

* add missing quotes in ecr policy ([#947](https://github.com/cds-snc/forms-terraform/issues/947)) ([5e56fec](https://github.com/cds-snc/forms-terraform/commit/5e56fec086add7ba294345cb887b72b398da2031))


### Miscellaneous Chores

* Add submissionId to handler ([#952](https://github.com/cds-snc/forms-terraform/issues/952)) ([9a8074a](https://github.com/cds-snc/forms-terraform/commit/9a8074a88da417509795aa27b4387f6d9d36303c))
* revert failing ecr policy ([#949](https://github.com/cds-snc/forms-terraform/issues/949)) ([734f2b6](https://github.com/cds-snc/forms-terraform/commit/734f2b6686503bdfe88f01089f6608cc44f868d3))
* temporarily disable data replication to data lake ([#951](https://github.com/cds-snc/forms-terraform/issues/951)) ([58c666e](https://github.com/cds-snc/forms-terraform/commit/58c666e65541f970f58a8b18a2450423ef6b6621))
* Use explicit accounts ids as org id does not work ([#954](https://github.com/cds-snc/forms-terraform/issues/954)) ([fd29a08](https://github.com/cds-snc/forms-terraform/commit/fd29a08fc6fd3d00c69819ae2b59b105b29ef1cf))

## [3.28.0](https://github.com/cds-snc/forms-terraform/compare/v3.27.6...v3.28.0) (2025-02-11)


### Features

* update the processed and historical data paths ([#941](https://github.com/cds-snc/forms-terraform/issues/941)) ([f8d245b](https://github.com/cds-snc/forms-terraform/commit/f8d245b6556eacc8525b8c07cdf5689a522f4fa9))

## [3.27.6](https://github.com/cds-snc/forms-terraform/compare/v3.27.5...v3.27.6) (2025-02-06)


### Miscellaneous Chores

* Add workflows for Glue in Production ([#939](https://github.com/cds-snc/forms-terraform/issues/939)) ([7d85345](https://github.com/cds-snc/forms-terraform/commit/7d853455b12d4433345d2f103a2a4ab8824951cb))
* Adds hCaptcha key setup ([#936](https://github.com/cds-snc/forms-terraform/issues/936)) ([0a6844c](https://github.com/cds-snc/forms-terraform/commit/0a6844c755f93452b6444c90180a45f47aa7587a))

## [3.27.5](https://github.com/cds-snc/forms-terraform/compare/v3.27.4...v3.27.5) (2025-02-06)


### Bug Fixes

* Set output of RDS subnet id to string ([#937](https://github.com/cds-snc/forms-terraform/issues/937)) ([29b33ba](https://github.com/cds-snc/forms-terraform/commit/29b33bae75231ff279a77ad366bbc386eac8083e))


### Miscellaneous Chores

* delete .lock.hcl file when running clean up step ([#933](https://github.com/cds-snc/forms-terraform/issues/933)) ([e6656f6](https://github.com/cds-snc/forms-terraform/commit/e6656f62e82c9404ef3c8c46f45207a06fb2f243))
* IDP waf dynamic Ip now blocks ([#935](https://github.com/cds-snc/forms-terraform/issues/935)) ([40b30f8](https://github.com/cds-snc/forms-terraform/commit/40b30f824009d9c86c883721ecd2d9ccdc837667))
* update terragrunt et al ([#931](https://github.com/cds-snc/forms-terraform/issues/931)) ([3a4e619](https://github.com/cds-snc/forms-terraform/commit/3a4e619e9f0bd45e36ebc1bff85bbbf40625720f))
* Use RDS reader endpoint for non-app use ([#938](https://github.com/cds-snc/forms-terraform/issues/938)) ([8738d66](https://github.com/cds-snc/forms-terraform/commit/8738d6656918d8d9dc7ebec12630a8e4b35408a5))

## [3.27.4](https://github.com/cds-snc/forms-terraform/compare/v3.27.3...v3.27.4) (2025-01-21)


### Miscellaneous Chores

* remove unused Vault Status global secondary index as well as Status property in Vault table ([#903](https://github.com/cds-snc/forms-terraform/issues/903)) ([259c3f8](https://github.com/cds-snc/forms-terraform/commit/259c3f821ee908192ba30f46f62916a291b542d8))
* update waf to take `v[0-9][0-9]` for api server ([#930](https://github.com/cds-snc/forms-terraform/issues/930)) ([e0b4cf1](https://github.com/cds-snc/forms-terraform/commit/e0b4cf1ac1ceb423e84cbe48fc97aef7acc43c1f))

## [3.27.3](https://github.com/cds-snc/forms-terraform/compare/v3.27.2...v3.27.3) (2025-01-17)


### Bug Fixes

* handle undefined answer for dynamic row question type ([#927](https://github.com/cds-snc/forms-terraform/issues/927)) ([d5910be](https://github.com/cds-snc/forms-terraform/commit/d5910bec75f047e8e074669ba71dacc796951a0e))

## [3.27.2](https://github.com/cds-snc/forms-terraform/compare/v3.27.1...v3.27.2) (2025-01-09)


### Bug Fixes

* handle empty string response for checkbox components ([#925](https://github.com/cds-snc/forms-terraform/issues/925)) ([dab2a51](https://github.com/cds-snc/forms-terraform/commit/dab2a5179f247fc49e8b40a61f4254817245bd37))

## [3.27.1](https://github.com/cds-snc/forms-terraform/compare/v3.27.0...v3.27.1) (2024-12-18)


### Bug Fixes

* maintenance page not showing up if Web App target group is not healthy but API one still is ([#919](https://github.com/cds-snc/forms-terraform/issues/919)) ([fcb6940](https://github.com/cds-snc/forms-terraform/commit/fcb6940efa8e7ccfab1e9900a1cf99d34f0e3fc4))


### Miscellaneous Chores

* add reference name to previously created Route53 health checks ([#922](https://github.com/cds-snc/forms-terraform/issues/922)) ([7030647](https://github.com/cds-snc/forms-terraform/commit/703064752a8bf3d8621a77b595c97468b00077f4))
* Update core terraform-modules to 10.2.1 ([#921](https://github.com/cds-snc/forms-terraform/issues/921)) ([c2459d3](https://github.com/cds-snc/forms-terraform/commit/c2459d3a0b59f7c0264e78e85a397e69d773e220))


### Code Refactoring

* replace use of Status with new Status#CreatedAt attribute when requesting Vault items ([#904](https://github.com/cds-snc/forms-terraform/issues/904)) ([3153f5b](https://github.com/cds-snc/forms-terraform/commit/3153f5bc02909e6e62b5fff2bb82aea8673d9a0f))

## [3.27.0](https://github.com/cds-snc/forms-terraform/compare/v3.26.0...v3.27.0) (2024-12-09)


### Features

* Update to latest dynamic IP blocking module ([#892](https://github.com/cds-snc/forms-terraform/issues/892)) ([d14ff31](https://github.com/cds-snc/forms-terraform/commit/d14ff31c704cec2a16375794ab4226a990779596))


### Bug Fixes

* Add egress rule from lambda to db ([#914](https://github.com/cds-snc/forms-terraform/issues/914)) ([de7d49d](https://github.com/cds-snc/forms-terraform/commit/de7d49d2f85d6f61b29270cc4837176356e87cfe))
* Add missing api path check on APP WAF rule ([#901](https://github.com/cds-snc/forms-terraform/issues/901)) ([9adb41d](https://github.com/cds-snc/forms-terraform/commit/9adb41dfaeb2aefecc3f81e2e606df73b229d02d))
* Inverted privatelink rule ([#913](https://github.com/cds-snc/forms-terraform/issues/913)) ([608d401](https://github.com/cds-snc/forms-terraform/commit/608d4016384937505a1d4210d68c12279624ff13))
* Nagware should handle form template with empty name ([#915](https://github.com/cds-snc/forms-terraform/issues/915)) ([c841f3a](https://github.com/cds-snc/forms-terraform/commit/c841f3a331600c547a6806ebda7796ad5cf61838))
* no healthy hosts alarms should treat missing data as breaching ([#918](https://github.com/cds-snc/forms-terraform/issues/918)) ([190752d](https://github.com/cds-snc/forms-terraform/commit/190752d294aefac3467c85f664391d517e2d7ea8))
* RDS serverless v2 Terraform sync ([#911](https://github.com/cds-snc/forms-terraform/issues/911)) ([d632641](https://github.com/cds-snc/forms-terraform/commit/d632641ad25d1e91e9f18aa566995f8527be7c16))
* update api cloudwatch filter to catch logMessage style json ([#902](https://github.com/cds-snc/forms-terraform/issues/902)) ([a5d57da](https://github.com/cds-snc/forms-terraform/commit/a5d57da9522e7b58649c8bb55f9064628d937305))
* WAF rule logic ([#900](https://github.com/cds-snc/forms-terraform/issues/900)) ([11b40f3](https://github.com/cds-snc/forms-terraform/commit/11b40f34be48b7bddf6377fcf6d7f1aca99ebd33))


### Miscellaneous Chores

* Comment out OR statement in WAF for now ([#899](https://github.com/cds-snc/forms-terraform/issues/899)) ([59cc5a9](https://github.com/cds-snc/forms-terraform/commit/59cc5a9327d959b60aeb9644120be7ce0c43bde0))
* Enable dynamic ip block on WAF ([#917](https://github.com/cds-snc/forms-terraform/issues/917)) ([7d9bf12](https://github.com/cds-snc/forms-terraform/commit/7d9bf129f9554b5fa26fc2fbdf016aedf1423024))
* re-enable TF management of rds module ([#916](https://github.com/cds-snc/forms-terraform/issues/916)) ([8111786](https://github.com/cds-snc/forms-terraform/commit/8111786f747a537d026c9c2bde6d30a7bffe64c9))
* remove POST request limit ([#909](https://github.com/cds-snc/forms-terraform/issues/909)) ([0db1847](https://github.com/cds-snc/forms-terraform/commit/0db1847bf07e5d48f5a375503614818f3458ae0c))
* Replace rds data client in reliability and nagware lambdas ([#906](https://github.com/cds-snc/forms-terraform/issues/906)) ([3c0bcff](https://github.com/cds-snc/forms-terraform/commit/3c0bcffbcb1cec2f38f73057bd5064b939ef6cd5))
* Seperate WAF uri checks contexts between API and App ([#896](https://github.com/cds-snc/forms-terraform/issues/896)) ([116af75](https://github.com/cds-snc/forms-terraform/commit/116af75889071cb865d42df86131fa56f3e35927))
* temporarily disable `rds` module plan/apply ([#908](https://github.com/cds-snc/forms-terraform/issues/908)) ([1060361](https://github.com/cds-snc/forms-terraform/commit/106036153e3189eca8c6561caaad4517589e930d))
* Update Lambda network and change RDS Lib in Lambdas ([#912](https://github.com/cds-snc/forms-terraform/issues/912)) ([788b0bc](https://github.com/cds-snc/forms-terraform/commit/788b0bc5a67689e4b36b05db6a73eb1e9837c51b))
* Update terraform, terragrunt,and AWS provider ([#898](https://github.com/cds-snc/forms-terraform/issues/898)) ([287c6d1](https://github.com/cds-snc/forms-terraform/commit/287c6d1df002201b0541220a4fd7c195f8ca78e8))

## [3.26.0](https://github.com/cds-snc/forms-terraform/compare/v3.25.3...v3.26.0) (2024-11-20)


### Features

* add CreatedAt field to Vault CONF# items ([#810](https://github.com/cds-snc/forms-terraform/issues/810)) ([f03ba83](https://github.com/cds-snc/forms-terraform/commit/f03ba83519d9c55432f03bad6cc0cc2851d24784))


### Bug Fixes

* Updates responses to use "-" for no responses ([#893](https://github.com/cds-snc/forms-terraform/issues/893)) ([a54e988](https://github.com/cds-snc/forms-terraform/commit/a54e988e73e9389b98a55dccf98776a99e82f206))

## [3.25.3](https://github.com/cds-snc/forms-terraform/compare/v3.25.2...v3.25.3) (2024-11-19)


### Bug Fixes

* Remove rate limiting WAF on api domain url ([#889](https://github.com/cds-snc/forms-terraform/issues/889)) ([0f92923](https://github.com/cds-snc/forms-terraform/commit/0f92923c9af7199c8582338c9a7337688b295225))


### Miscellaneous Chores

* Setup Next.js server action key ([#887](https://github.com/cds-snc/forms-terraform/issues/887)) ([77bcdb4](https://github.com/cds-snc/forms-terraform/commit/77bcdb418e95714755f077e6ddb3260f40533a7b))

## [3.25.2](https://github.com/cds-snc/forms-terraform/compare/v3.25.1...v3.25.2) (2024-11-06)


### Miscellaneous Chores

* **deps:** update all non-major github action dependencies ([#885](https://github.com/cds-snc/forms-terraform/issues/885)) ([8cca769](https://github.com/cds-snc/forms-terraform/commit/8cca769c825a6e08d842d9abab82787ffadcccbe))
* Update Readme  ([#884](https://github.com/cds-snc/forms-terraform/issues/884)) ([5cb6a59](https://github.com/cds-snc/forms-terraform/commit/5cb6a59698bde99d2b48369b20056ece6a489a8d))

## [3.25.1](https://github.com/cds-snc/forms-terraform/compare/v3.25.0...v3.25.1) (2024-10-31)


### Bug Fixes

* Certain Redis infra features need to be disabled for localstack ([#880](https://github.com/cds-snc/forms-terraform/issues/880)) ([38d69c1](https://github.com/cds-snc/forms-terraform/commit/38d69c150281ff99d8cb4342b906887426250416))


### Miscellaneous Chores

* Remove warn on grant and revoke form access ([#883](https://github.com/cds-snc/forms-terraform/issues/883)) ([d434639](https://github.com/cds-snc/forms-terraform/commit/d43463937c3bd49760ca77d92f405aff19cc8fa0))

## [3.25.0](https://github.com/cds-snc/forms-terraform/compare/v3.24.3...v3.25.0) (2024-10-21)


### Features

* add IdP, API and form submit performance tests ([#853](https://github.com/cds-snc/forms-terraform/issues/853)) ([15c4d56](https://github.com/cds-snc/forms-terraform/commit/15c4d56e786c1bb68719c34b1078bce7dc8b1d96))
* add SSM parameters for the load tests ([#872](https://github.com/cds-snc/forms-terraform/issues/872)) ([b6204ff](https://github.com/cds-snc/forms-terraform/commit/b6204ffbba0c050d9ad6aa7d4b7e0f0eac0ec45a))


### Bug Fixes

* Add missing workflow change for staging terraform plan ([#870](https://github.com/cds-snc/forms-terraform/issues/870)) ([1de10af](https://github.com/cds-snc/forms-terraform/commit/1de10af3fc0c5d6d296e4d17f86a332e14edf05b))
* **deps:** update all minor dependencies ([#516](https://github.com/cds-snc/forms-terraform/issues/516)) ([a493e1c](https://github.com/cds-snc/forms-terraform/commit/a493e1cbdf9e66136583a2add706aa3796af7f49))
* **deps:** update dependency axios to v1.7.4 [security] ([#779](https://github.com/cds-snc/forms-terraform/issues/779)) ([c067222](https://github.com/cds-snc/forms-terraform/commit/c0672227bf1033e59df5da577bc1cdc892fc3783))


### Miscellaneous Chores

* **deps:** update all non-major docker images ([#704](https://github.com/cds-snc/forms-terraform/issues/704)) ([407cb32](https://github.com/cds-snc/forms-terraform/commit/407cb329e573a20aa191fbfb29d83119f5c7608b))
* upgrade ALB to latest recommend SSL policy ([#868](https://github.com/cds-snc/forms-terraform/issues/868)) ([591f3c8](https://github.com/cds-snc/forms-terraform/commit/591f3c813747b6de196ef8a3601b4eb0ffc3a525))

## [3.24.3](https://github.com/cds-snc/forms-terraform/compare/v3.24.2...v3.24.3) (2024-10-15)


### Bug Fixes

* Increase default timeout to Notify ([#867](https://github.com/cds-snc/forms-terraform/issues/867)) ([0316710](https://github.com/cds-snc/forms-terraform/commit/0316710fc5c6e2419750f0e033c955d43af679ec))


### Miscellaneous Chores

* **deps:** update all non-major github action dependencies ([#861](https://github.com/cds-snc/forms-terraform/issues/861)) ([924fd3b](https://github.com/cds-snc/forms-terraform/commit/924fd3bbda1a40c163b7a718b35ed559471a190d))
* **deps:** update all non-major github action dependencies ([#866](https://github.com/cds-snc/forms-terraform/issues/866)) ([b6571e3](https://github.com/cds-snc/forms-terraform/commit/b6571e3b08d9bc13313ec79de7c4b3e52da5a164))
* suppress user OIDC request errors ([#865](https://github.com/cds-snc/forms-terraform/issues/865)) ([9995021](https://github.com/cds-snc/forms-terraform/commit/99950212a2bb42dd3bf3dcdfdb16448ec2d72ec2))
* synced file(s) with cds-snc/site-reliability-engineering ([#863](https://github.com/cds-snc/forms-terraform/issues/863)) ([704ad73](https://github.com/cds-snc/forms-terraform/commit/704ad7347ed90d64aae281bd567fb149d92557d6))

## [3.24.2](https://github.com/cds-snc/forms-terraform/compare/v3.24.1...v3.24.2) (2024-10-07)


### Bug Fixes

* IdP task memory value ([#855](https://github.com/cds-snc/forms-terraform/issues/855)) ([2d43e7b](https://github.com/cds-snc/forms-terraform/commit/2d43e7b567ee7e25101628ad59bd6395aa6424f0))
* Process formattedDate type response ([#862](https://github.com/cds-snc/forms-terraform/issues/862)) ([e56a600](https://github.com/cds-snc/forms-terraform/commit/e56a600756abdf1d786ae459a127bfac0aea5820))
* set database max connection properties ([#859](https://github.com/cds-snc/forms-terraform/issues/859)) ([1675dc1](https://github.com/cds-snc/forms-terraform/commit/1675dc141e61a67aadca54eb9ed7e0e7fb092eeb))

## [3.24.1](https://github.com/cds-snc/forms-terraform/compare/v3.24.0...v3.24.1) (2024-10-01)


### Bug Fixes

* adjust IdP CloudWatch alarm error filter ([#849](https://github.com/cds-snc/forms-terraform/issues/849)) ([7444d25](https://github.com/cds-snc/forms-terraform/commit/7444d258123d0b1dfe7c181c8e0637b5f425bbc0))


### Miscellaneous Chores

* **deps:** update actions/setup-node action to v4.0.4 ([#851](https://github.com/cds-snc/forms-terraform/issues/851)) ([63998b7](https://github.com/cds-snc/forms-terraform/commit/63998b743cfe5d7a61b850953046f02b4d45c2fa))
* synced file(s) with cds-snc/site-reliability-engineering ([#848](https://github.com/cds-snc/forms-terraform/issues/848)) ([b43f0f2](https://github.com/cds-snc/forms-terraform/commit/b43f0f2eb1141bb096055b9ade9f01853b76d8e4))

## [3.24.0](https://github.com/cds-snc/forms-terraform/compare/v3.23.1...v3.24.0) (2024-09-23)


### Features

* add module to manage IPv4 blocklist ([#844](https://github.com/cds-snc/forms-terraform/issues/844)) ([76b0f03](https://github.com/cds-snc/forms-terraform/commit/76b0f036e3288004ca15ad02d426fcae51ad323f))


### Miscellaneous Chores

* Add zitadel key for app ([#847](https://github.com/cds-snc/forms-terraform/issues/847)) ([9c174ad](https://github.com/cds-snc/forms-terraform/commit/9c174ad2e24de873813f9935b207fd0d174866eb))
* remove the `moved` blocks that are no longer needed ([#845](https://github.com/cds-snc/forms-terraform/issues/845)) ([5f70819](https://github.com/cds-snc/forms-terraform/commit/5f70819c81b9db1ded64d4e29bc7427fd6e612f4))

## [3.23.1](https://github.com/cds-snc/forms-terraform/compare/v3.23.0...v3.23.1) (2024-09-23)


### Bug Fixes

* set default OIDC token expiry times ([#834](https://github.com/cds-snc/forms-terraform/issues/834)) ([ffd6e97](https://github.com/cds-snc/forms-terraform/commit/ffd6e9707742a1ba27ecfa1e5ce1b0711de9d230))
* test if Notify Slack log message JSON is valid ([#838](https://github.com/cds-snc/forms-terraform/issues/838)) ([2878a0d](https://github.com/cds-snc/forms-terraform/commit/2878a0d136b581c64845b63fdbe1020ca938a158))
* upgrade `ecs` module to stop task revision flip-flop ([#842](https://github.com/cds-snc/forms-terraform/issues/842)) ([d2b9882](https://github.com/cds-snc/forms-terraform/commit/d2b9882251157f3e3a209590b8c644ded274f666))


### Miscellaneous Chores

* **deps:** update actions/create-github-app-token action to v1.11.0 ([#843](https://github.com/cds-snc/forms-terraform/issues/843)) ([df37373](https://github.com/cds-snc/forms-terraform/commit/df3737352f39d2c8d6798c4a645e41190fb1f1a2))
* downgrade to Zitadel v2.61.1 ([#833](https://github.com/cds-snc/forms-terraform/issues/833)) ([678ebca](https://github.com/cds-snc/forms-terraform/commit/678ebca42f804c58c408d7b9ba909c8ec9bb3d87))
* reduce Zitadel token timeout to 30 mins ([#837](https://github.com/cds-snc/forms-terraform/issues/837)) ([89b31c5](https://github.com/cds-snc/forms-terraform/commit/89b31c54e3c76c50f8adb8124391c8b742e908ba))
* remove IdP and API feature flags ([#841](https://github.com/cds-snc/forms-terraform/issues/841)) ([5003a42](https://github.com/cds-snc/forms-terraform/commit/5003a42f63293cc209f2ae4e3b22212484d4c91e))
* suppress `context canceled` IdP errors ([#836](https://github.com/cds-snc/forms-terraform/issues/836)) ([b5fd220](https://github.com/cds-snc/forms-terraform/commit/b5fd22029fa2ac1dfbbbe6196ff76ac178cd6e16))
* synced file(s) with cds-snc/site-reliability-engineering ([#825](https://github.com/cds-snc/forms-terraform/issues/825)) ([d47d9cf](https://github.com/cds-snc/forms-terraform/commit/d47d9cfa17c4fc1d41d5bb01f4150c38a96416a5))
* synced file(s) with cds-snc/site-reliability-engineering ([#835](https://github.com/cds-snc/forms-terraform/issues/835)) ([8210659](https://github.com/cds-snc/forms-terraform/commit/82106595a875aef2b4c6dcad8ee32060c2dd1196))
* upgrade to Zitadel v2.62.0 ([#832](https://github.com/cds-snc/forms-terraform/issues/832)) ([099a5b2](https://github.com/cds-snc/forms-terraform/commit/099a5b2e58a87d1c389ad0a3864712f26a618bc5))

## [3.23.0](https://github.com/cds-snc/forms-terraform/compare/v3.22.0...v3.23.0) (2024-09-16)


### Features

* API Audit Logs ([#824](https://github.com/cds-snc/forms-terraform/issues/824)) ([401d6b9](https://github.com/cds-snc/forms-terraform/commit/401d6b9a5945a0907f3ae91ed047a76c1007fdca))
* create Forms API OIDC role for releases ([#830](https://github.com/cds-snc/forms-terraform/issues/830)) ([6ded50e](https://github.com/cds-snc/forms-terraform/commit/6ded50efb3c23d286c25bf14210ee92c6c8272d9))


### Miscellaneous Chores

* **deps:** update all non-major github action dependencies ([#828](https://github.com/cds-snc/forms-terraform/issues/828)) ([a3988e8](https://github.com/cds-snc/forms-terraform/commit/a3988e8fbd8d6c34920a6fa3c0139f0cc54abfa0))

## [3.22.0](https://github.com/cds-snc/forms-terraform/compare/v3.21.0...v3.22.0) (2024-09-13)


### Features

* deploy API to prod ([#826](https://github.com/cds-snc/forms-terraform/issues/826)) ([193b470](https://github.com/cds-snc/forms-terraform/commit/193b470a9a43a8b13f29388746ebaf08060ba30d))

## [3.21.0](https://github.com/cds-snc/forms-terraform/compare/v3.20.0...v3.21.0) (2024-09-12)


### Features

* deploy IdP to production ([#822](https://github.com/cds-snc/forms-terraform/issues/822)) ([c8017c7](https://github.com/cds-snc/forms-terraform/commit/c8017c701ab3e3c0d5a64deaeddd3c128923ea3f))

## [3.20.0](https://github.com/cds-snc/forms-terraform/compare/v3.19.0...v3.20.0) (2024-09-12)


### Features

* add IPv4 blocklist rule to App, IdP WAF ACLs ([#821](https://github.com/cds-snc/forms-terraform/issues/821)) ([09210fb](https://github.com/cds-snc/forms-terraform/commit/09210fb062a06cf8d99c8e80f3c68217dd8b17fc))


### Bug Fixes

* add HealthyHostCount alarms to App, IdP, API ([#818](https://github.com/cds-snc/forms-terraform/issues/818)) ([0e2301d](https://github.com/cds-snc/forms-terraform/commit/0e2301d78815ea856a634cbb5aa3d83000c57954))
* remove OK actions from critical alarms ([#819](https://github.com/cds-snc/forms-terraform/issues/819)) ([27de887](https://github.com/cds-snc/forms-terraform/commit/27de887afba0ce8d80a8bceb3fe22048795781c2))
* use maximum CPU/memory stat for alarms ([#820](https://github.com/cds-snc/forms-terraform/issues/820)) ([9e53e16](https://github.com/cds-snc/forms-terraform/commit/9e53e164ce9a498b41695d80223aec82920cd877))


### Miscellaneous Chores

* synced file(s) with cds-snc/site-reliability-engineering ([#814](https://github.com/cds-snc/forms-terraform/issues/814)) ([7cd2407](https://github.com/cds-snc/forms-terraform/commit/7cd24077668f4bf38a0fda09698b68bcc52a15b2))

## [3.19.0](https://github.com/cds-snc/forms-terraform/compare/v3.18.3...v3.19.0) (2024-09-10)


### Features

* add a new GSI to support the API endpoint returning the submission names sorted by creation time ([#799](https://github.com/cds-snc/forms-terraform/issues/799)) ([0e782ab](https://github.com/cds-snc/forms-terraform/commit/0e782ab0ec11fd045b32341850a47251c0c6b20d))
* add ENVIRONMENT_MODE env var to API ECS task ([#797](https://github.com/cds-snc/forms-terraform/issues/797)) ([00176a4](https://github.com/cds-snc/forms-terraform/commit/00176a4c96f7a75c793ee1a5156782730857577d))
* add Freshdesk API key secret to API ECS task ([#795](https://github.com/cds-snc/forms-terraform/issues/795)) ([bfc68e9](https://github.com/cds-snc/forms-terraform/commit/bfc68e98aea6ad7d462bb3729cf96dfb6cc4f391))
* add Redis URL to the API ECS task ([#801](https://github.com/cds-snc/forms-terraform/issues/801)) ([0530fe5](https://github.com/cds-snc/forms-terraform/commit/0530fe5e5ad06fe866390f8dfca14e0387a556b4))
* allow API to access Redis ([#790](https://github.com/cds-snc/forms-terraform/issues/790)) ([e127f66](https://github.com/cds-snc/forms-terraform/commit/e127f66a80d6fab9dfde706c3de039c4e8206e41))
* cache the Nagware overdue response form IDs ([#808](https://github.com/cds-snc/forms-terraform/issues/808)) ([8ef2d6a](https://github.com/cds-snc/forms-terraform/commit/8ef2d6a8bb5f43773870ba05bcb8289b05c3b48b))
* Nagware Lambda connect to Redis ([#807](https://github.com/cds-snc/forms-terraform/issues/807)) ([c57f45b](https://github.com/cds-snc/forms-terraform/commit/c57f45be2c57db37d8329c2caade5b6522d72a7f))
* run Nagware every day ([#811](https://github.com/cds-snc/forms-terraform/issues/811)) ([d87a640](https://github.com/cds-snc/forms-terraform/commit/d87a64016da380ab4da0d21da664c00dcb8197fa))
* use RDS Proxy for IdP database connection pool ([#788](https://github.com/cds-snc/forms-terraform/issues/788)) ([c3f7b7b](https://github.com/cds-snc/forms-terraform/commit/c3f7b7bc4d85fa787c4e2167cd1ccca5c28a211d))


### Bug Fixes

* add missing input variable for sentry api ([#798](https://github.com/cds-snc/forms-terraform/issues/798)) ([337f220](https://github.com/cds-snc/forms-terraform/commit/337f220c21965772b42799d97da31bf70141e887))
* allow API ECS task runtime secret access ([#815](https://github.com/cds-snc/forms-terraform/issues/815)) ([85940c3](https://github.com/cds-snc/forms-terraform/commit/85940c37770598c28d72306bbd09df4ab7b9611a))
* Allow API to access RDS connection url secret ([#813](https://github.com/cds-snc/forms-terraform/issues/813)) ([ea2f71c](https://github.com/cds-snc/forms-terraform/commit/ea2f71c9e5e9fbf2127d22e8c121b1c05513e304))
* API Redis URL add protocol and port ([#802](https://github.com/cds-snc/forms-terraform/issues/802)) ([ab6a87e](https://github.com/cds-snc/forms-terraform/commit/ab6a87eb3e87bd4d65355c02094e8ed402981b8c))
* deploy new IdP image if changes ([#805](https://github.com/cds-snc/forms-terraform/issues/805)) ([921fbc9](https://github.com/cds-snc/forms-terraform/commit/921fbc9299a9dedcc070a6e62b9d49885f4c9dfb))
* ECS task to access to Sentry secret ([#803](https://github.com/cds-snc/forms-terraform/issues/803)) ([3dc3824](https://github.com/cds-snc/forms-terraform/commit/3dc382498d7823edc12dd286d362be24a8ec5639))
* increase blanket WAF ACL rate limit ([#812](https://github.com/cds-snc/forms-terraform/issues/812)) ([c1aca16](https://github.com/cds-snc/forms-terraform/commit/c1aca16e9834a51c9af08a85a5779ed17575543c))


### Miscellaneous Chores

* **deps:** update aws-actions/amazon-ecs-render-task-definition action to v1.5.1 ([#809](https://github.com/cds-snc/forms-terraform/issues/809)) ([83db613](https://github.com/cds-snc/forms-terraform/commit/83db6139362edd302b15c61cc3111e1f034ed052))
* increase memory scaling limit to 25 percent ([#800](https://github.com/cds-snc/forms-terraform/issues/800)) ([7ee82c4](https://github.com/cds-snc/forms-terraform/commit/7ee82c4112ba8b37f8a8cce092f4bf7a3043c201))
* Sentry API key setup ([#796](https://github.com/cds-snc/forms-terraform/issues/796)) ([5e6bb31](https://github.com/cds-snc/forms-terraform/commit/5e6bb3122f6abbe818d1126dba4cd91e559de22a))
* synced file(s) with cds-snc/site-reliability-engineering ([#777](https://github.com/cds-snc/forms-terraform/issues/777)) ([78d2bc9](https://github.com/cds-snc/forms-terraform/commit/78d2bc9df269cca97b91ba05a842f11dab75d47e))
* upgrade Zitadel to v2.55.6 ([#806](https://github.com/cds-snc/forms-terraform/issues/806)) ([b108e32](https://github.com/cds-snc/forms-terraform/commit/b108e327117936929b84814ef840c153d663482f))


### Code Refactoring

* remove axios instance in GCNotifyClient ([#804](https://github.com/cds-snc/forms-terraform/issues/804)) ([6d2a721](https://github.com/cds-snc/forms-terraform/commit/6d2a721e664f90207e8a98b9316e64d402c6427d))
* reword error log for when a GC Notify request times out ([#792](https://github.com/cds-snc/forms-terraform/issues/792)) ([132e992](https://github.com/cds-snc/forms-terraform/commit/132e9924f462bebec3e64272666c84179fb40dfc))

## [3.18.3](https://github.com/cds-snc/forms-terraform/compare/v3.18.2...v3.18.3) (2024-08-27)


### Bug Fixes

* wrong import in Cognito Email Sender lambda function ([#786](https://github.com/cds-snc/forms-terraform/issues/786)) ([f1cfae9](https://github.com/cds-snc/forms-terraform/commit/f1cfae997c84283fda2d8b7239d2bd8a13c71576))

## [3.18.2](https://github.com/cds-snc/forms-terraform/compare/v3.18.1...v3.18.2) (2024-08-22)


### Bug Fixes

* add api missing variables (zitadel domain and app key) ([#781](https://github.com/cds-snc/forms-terraform/issues/781)) ([0d92933](https://github.com/cds-snc/forms-terraform/commit/0d929332552856ec0561647ae566e768b50f9734))
* attach permission to retrieve secrets to API ECS task ([#783](https://github.com/cds-snc/forms-terraform/issues/783)) ([b2d73f8](https://github.com/cds-snc/forms-terraform/commit/b2d73f8582278356710151e85094acd307215340))
* permission to use DynamoDB was not properly set in the ECS task configuration ([#784](https://github.com/cds-snc/forms-terraform/issues/784)) ([ee6c425](https://github.com/cds-snc/forms-terraform/commit/ee6c425f5747cfb291b9cb53189b6b09818f904b))
* permission to use KMS was not properly set in the ECS task configuration ([#785](https://github.com/cds-snc/forms-terraform/issues/785)) ([6101829](https://github.com/cds-snc/forms-terraform/commit/610182938a8c272aa3bc8aa40fa4a982c15940af))

## [3.18.1](https://github.com/cds-snc/forms-terraform/compare/v3.18.0...v3.18.1) (2024-08-13)


### Bug Fixes

* Attach files from fileInputs in a dynamicRow ([#776](https://github.com/cds-snc/forms-terraform/issues/776)) ([b8084a8](https://github.com/cds-snc/forms-terraform/commit/b8084a8bfc00d2b96f90e6a90dc2bb15605dd500))

## [3.18.0](https://github.com/cds-snc/forms-terraform/compare/v3.17.0...v3.18.0) (2024-08-12)


### Features

* add new secrets for Zitadel ([#764](https://github.com/cds-snc/forms-terraform/issues/764)) ([631db20](https://github.com/cds-snc/forms-terraform/commit/631db2041b333b16248da88897ebb1796d62dcb1))


### Bug Fixes

* remove unused secret ([#772](https://github.com/cds-snc/forms-terraform/issues/772)) ([e812b7d](https://github.com/cds-snc/forms-terraform/commit/e812b7d7199273bc3918e9fbf58bb04c23cf1583))
* secret arn output name ([#771](https://github.com/cds-snc/forms-terraform/issues/771)) ([eadcb8a](https://github.com/cds-snc/forms-terraform/commit/eadcb8aad8970f52e6599904a3b25cb054c54b17))
* Secrets vs variable ([#770](https://github.com/cds-snc/forms-terraform/issues/770)) ([34b4da0](https://github.com/cds-snc/forms-terraform/commit/34b4da018585b5b3a8829f75f1d63d80b3fe156c))
* set API service to use latest task def ([#767](https://github.com/cds-snc/forms-terraform/issues/767)) ([769eae9](https://github.com/cds-snc/forms-terraform/commit/769eae96a6fd9f2865caece82fb6193230758a39))


### Miscellaneous Chores

* add alarms for all IdP LB target groups ([#773](https://github.com/cds-snc/forms-terraform/issues/773)) ([cb8768c](https://github.com/cds-snc/forms-terraform/commit/cb8768c559a97eb44b5c92e5267ec62680815c4d))
* add AWS CLI prerequisite to README.md ([#775](https://github.com/cds-snc/forms-terraform/issues/775)) ([0001d46](https://github.com/cds-snc/forms-terraform/commit/0001d46d0f5423148c89786dbbf970661041b15a))
* prepare zitadel variables for production deployment ([#774](https://github.com/cds-snc/forms-terraform/issues/774)) ([1607916](https://github.com/cds-snc/forms-terraform/commit/16079169207262eb5e9c611823dd55c7a4d0822c))
* update IdP DMARC security email ([#769](https://github.com/cds-snc/forms-terraform/issues/769)) ([4a7e047](https://github.com/cds-snc/forms-terraform/commit/4a7e0479a0ccc5852b7dc7062503a614e68d1053))

## [3.17.0](https://github.com/cds-snc/forms-terraform/compare/v3.16.0...v3.17.0) (2024-08-08)


### Features

* add API CloudWatch alarms ([#754](https://github.com/cds-snc/forms-terraform/issues/754)) ([f7d3e38](https://github.com/cds-snc/forms-terraform/commit/f7d3e38af3179a302944971a30c87bce2e9f0aae))
* add HTTP2 IdP target group ([#762](https://github.com/cds-snc/forms-terraform/issues/762)) ([e49bcb6](https://github.com/cds-snc/forms-terraform/commit/e49bcb6f8fbe5787457a1880af1543957992b5a0))
* update IdP WAF to block large requests ([#756](https://github.com/cds-snc/forms-terraform/issues/756)) ([4fae4a4](https://github.com/cds-snc/forms-terraform/commit/4fae4a4f84ca0e8f6749ba47a05df4576884f39f))


### Bug Fixes

* add label match custom rule ([#760](https://github.com/cds-snc/forms-terraform/issues/760)) ([e8a76c8](https://github.com/cds-snc/forms-terraform/commit/e8a76c84ce9419493f4ff9db9fa6ed7bd35be2d4))
* exclude EC2MetaDataSSRF_Body WAF ACL rule ([#759](https://github.com/cds-snc/forms-terraform/issues/759)) ([4dceba4](https://github.com/cds-snc/forms-terraform/commit/4dceba4de51b38fa6d43c8d219c3909ab504698d))
* IdP listener rule for well-known config ([#763](https://github.com/cds-snc/forms-terraform/issues/763)) ([0e0010c](https://github.com/cds-snc/forms-terraform/commit/0e0010cb9a91da666f2e43763e7ec949bfe4c007))
* switch IdP LB protocol to HTTP1 ([#758](https://github.com/cds-snc/forms-terraform/issues/758)) ([2379e06](https://github.com/cds-snc/forms-terraform/commit/2379e06bef5efcd46d5eca6f70a839e0bdd2dbaf))


### Miscellaneous Chores

* add OpenAPI doc route to WAF ([#761](https://github.com/cds-snc/forms-terraform/issues/761)) ([010fcec](https://github.com/cds-snc/forms-terraform/commit/010fcec35ef9067fbcbff92fc434e4985fb964ad))
* added rds_connector_db_password variable to RDS terragrunt.hcl file ([#757](https://github.com/cds-snc/forms-terraform/issues/757)) ([2173fca](https://github.com/cds-snc/forms-terraform/commit/2173fca3607bd889ec83f7e618818439181bae51))
* remove completed `import` blocks ([#755](https://github.com/cds-snc/forms-terraform/issues/755)) ([2170624](https://github.com/cds-snc/forms-terraform/commit/217062440846414622cdf3a555c8f27c091e250f))
* rename ECS API task from form-api to forms-api ([#766](https://github.com/cds-snc/forms-terraform/issues/766)) ([391ff5e](https://github.com/cds-snc/forms-terraform/commit/391ff5e09f319c171c9a15a964b109ccbe3c6248))
* synced file(s) with cds-snc/site-reliability-engineering ([#752](https://github.com/cds-snc/forms-terraform/issues/752)) ([67e6358](https://github.com/cds-snc/forms-terraform/commit/67e6358ecc5b176ec58c1085a3b002288ea614d9))
* upgrade to Release Please v4 ([#765](https://github.com/cds-snc/forms-terraform/issues/765)) ([ae1920e](https://github.com/cds-snc/forms-terraform/commit/ae1920ed6544ef0744350a077e3b3c1a59fa4bd0))

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
