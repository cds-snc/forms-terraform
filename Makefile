include .env
export $(shell sed 's/=.*//' .env)
export AWS_PROFILE=development
export APP_ENV=development

guard-%:
	@ if [ "${${*}}" = "" ]; then \
	echo "Environment variable $* not set"; \
	exit 1; \
	fi

default: help

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/→/'

checkov:            ## Checkov security static analysis
	checkov -d aws

fmt:                ## Format all .tf files
	cd aws
	terraform fmt -recursive

hclfmt:             ## Format all .hcl files
	cd env/
	terragrunt run-all hclfmt

validate:           ## Terragrunt validate all resources
	cd env/
	terragrunt run-all validate

build_env: 	    ## Build Development environment
	./local_dev_files/build_dev_env.sh

build_module: 	## Build specific module
	./local_dev_files/build_dev_env.sh $(name)

destroy_env: 	## Destroy Development environment
	./local_dev_files/destroy_dev_env.sh

create_certs: 	## Create Development certificates
	./local_dev_files/create_vpn_certs.sh

connect_env: 	## Connect to Development environment
	./local_dev_files/connect_vpn.sh

lambda: ## Build specific lambda image and deploy to local environment
	echo Building lambda $(name)
	./local_dev_files/build_and_deploy_lambda.sh $(name)

lambdas: ## Build all lambda images and deploy to local environment
	echo Building all lambdas
	./local_dev_files/build_and_deploy_lambda.sh

clear_terragrunt_cache: ## Clear Terragrunt cache
	./local_dev_files/clean_terragrunt.sh

sso_login: ## Login to AWS SSO
	./local_dev_files/sso_login.sh $(profile)

# Dependency guards

lambda lambdas connect_env create_certs destroy_env build_env build_module: guard-AWS_ACCOUNT_ID
lambda lambdas connect_env destroy_env build_env build_module: sso_login

build_env build_module: guard-STAGING_AWS_ACCOUNT_ID


.PHONY: \
	checkov \
	default \
	fmt \
	hclfmt \
	help \
	terragrunt \
	validate \
	build_env \
	build_module \
	destroy_env \
	create_certs \
	connect_env \
	clear_terragrunt_cache \
	sso_login \
	lambda \
	lambdas 