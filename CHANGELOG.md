# Changelog

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
