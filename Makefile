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

build_dev: 	    ## Build Development environment
	./local_dev_files/build_dev_env.sh

destroy_dev: 	## Destroy Development environment
	./local_dev_files/destroy_dev_env.sh

create_dev_certs: 	## Create Development certificates
	./local_dev_files/create_vpn_certs.sh

connect_dev: 	## Connect to Development environment
	./local_dev_files/connect_vpn.sh

lambda: ## Build specific lambda image and deploy to local environment
	echo Building lambda $(name)
	./local_dev_files/import_envs.sh
	./local_dev_files/build_and_deploy_lambda.sh $(name)

lambdas: ## Build all lambda images and deploy to local environment
	echo Building all lambdas
	./local_dev_files/build_and_deploy_lambda.sh

lambda lambdas connect_dev create_dev_certs destroy_dev build_dev: guard-AWS_ACCOUNT_ID

build_dev: guard-STAGING_AWS_ACCOUNT_ID


.PHONY: \
	checkov \
	default \
	fmt \
	hclfmt \
	help \
	terragrunt \
	validate \
	build_dev \
	destroy_dev \
	create_dev_certs \
	connect_dev