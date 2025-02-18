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

terragrunt:         ## Create localstack resources
	./aws/app/lambda/deps.sh delete
	.devcontainer/scripts/terraform_apply_localstack.sh

build_dev: 	    ## Build Development environment
	./local_dev_files/build_dev_env.sh

destroy_dev: 	## Destroy Development environment
	./local_dev_files/destroy_dev_env.sh

create_dev_certs: 	## Create Development certificates
	./local_dev_files/create_vpn_certs.sh

connect_dev: 	## Connect to Development environment
	./local_dev_files/connect_vpn.sh


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