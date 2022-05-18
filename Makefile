default: help

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/→/'

checkov: 	## Checkov security static analysis
	checkov -d aws

fmt: 		## Format all .tf files
	cd aws &&\
	terraform fmt -recursive

hclfmt: 	## Format all .hcl files
	cd env/scratch &&\
	terragrunt run-all hclfmt

validate: 	## Terragrunt validate all resources
	cd env/scratch &&\
	terragrunt run-all validate

lambdas:
	cd aws/app/lambda &&\
	./start_local_lambdas.sh

.PHONY: \
	checkov \
	default \
	fmt \
	hclfmt \
	help \
	validate