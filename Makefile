# use some sensible default shell settings
SHELL := /bin/bash
.ONESHELL:
.SILENT:
.DEFAULT_GOAL := help

RED = '\033[1;31m'
CYAN = '\033[0;36m'
NC = '\033[0m'

# local variables
HHC_FUNCTION = auth
HHC_APPLICATION = verify

# default variables
HHC_ENVIRONMENT ?= devel
HHC_INSTANCE ?= master
HHC_FULL_NAME = $(HHC_FUNCTION)-$(HHC_APPLICATION)-$(HHC_INSTANCE)

# Devel docker repository
HHC_DOCKER_REPO_ID ?= 767894820823
HHC_DOCKER_REPO = $(HHC_DOCKER_REPO_ID).dkr.ecr.ap-southeast-2.amazonaws.com

# available options
OPT_ENVIRONMENT = ^(devel|stage|prod)$$

# git variables
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_HASH := $(shell git rev-parse --short=8 HEAD)

ifeq ($(GIT_BRANCH), HEAD)
	GIT_BRANCH := $(BUILDKITE_BRANCH)
endif

# current python image
export HHC_IMAGE=$(HHC_DOCKER_REPO)/$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-$(GIT_HASH)

# terraform configuration
TF_ARTIFACT = ./$(HHC_FULL_NAME).tfplan
TF_VARS := -var 'function=$(HHC_FUNCTION)' \
           -var 'application=$(HHC_APPLICATION)' \
		   -var 'instance=$(HHC_INSTANCE)' \
	       -var-file=../config/$(HHC_ENVIRONMENT).tfvars
TF_OUTPUT = ./infra/$(HHC_FULL_NAME).json
TF_OUTPUT_API = $(shell cat $(TF_OUTPUT) | jq -r ".api.value")
TF_OUTPUT_API_KEY = $(shell cat $(TF_OUTPUT) | jq -r ".test_api_key.value")

# docker-compose calls
PYTHON = docker-compose run python
TERRAFORM = docker-compose run terraform
SONAR = docker-compose run sonar
AWSCLI = docker-compose run awscli


##@ Main targets
build: pyimage pypublish pyaudit pytype pyformat pytest pypackage ## Check, lint, build, unit test, package, and publish code
scan: sonarscan ## Static analysis
deploy: tfformat tfvalidate tfplan tfapply ## Format, validate, plan, and apply terraform
test: testapi ## Test api post deployment
destroy: tfdestroy ## Destroy environment


##@ Authorisation targets
.PHONY: authconfig
authconfig: ## Authorisation configuration
	echo -e $(CYAN)Authorisation configuration$(NC)
	$(AWSCLI) configure sso

.PHONY: auth
auth: ## Authorisation into default profile
	echo -e $(CYAN)Authorisation into default profile$(NC)
	$(AWSCLI) sso login


##@ Build targets
.PHONY: pyimage
pyimage: ## Create Python docker image
	echo -e $(CYAN)Creating Python docker image$(NC)
	docker build \
		-t "$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-latest" \
		-t "$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-${GIT_BRANCH}" \
		-t "$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-${GIT_HASH}" \
		-t "$(HHC_DOCKER_REPO)/$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-latest" \
		-t "$(HHC_DOCKER_REPO)/$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-$(GIT_BRANCH)" \
		-t "$(HHC_DOCKER_REPO)/$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-$(GIT_HASH)" \
		./src

.PHONY: pypublish
pypublish: ## Publish Python docker image
	echo -e $(CYAN)Publishing Python docker image$(NC)
	# Hack start
	# There seems to be a replication delay between when an ECR password is issued and when it can be used.
	# Added delay between two identical calls to login into ECR. The first always fails and the second succeeds.
	$(AWSCLI) ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin $(HHC_DOCKER_REPO)
	sleep 5
	# Hack end
	$(AWSCLI) ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin $(HHC_DOCKER_REPO)
	docker push "$(HHC_DOCKER_REPO)/$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-latest"
	docker push "$(HHC_DOCKER_REPO)/$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-$(GIT_BRANCH)"
	docker push "$(HHC_DOCKER_REPO)/$(HHC_FUNCTION)-$(HHC_APPLICATION):$(HHC_INSTANCE)-$(GIT_HASH)"

.PHONY: pyaudit
pyaudit: ## Check Python dependencies
	echo -e $(CYAN)Checking Python dependencies$(NC)
	$(PYTHON) pip-audit --desc on

.PHONY: pytype
pytype: ## Type check Python code
	echo -e $(CYAN)Type checking code$(NC) && \
	$(PYTHON) mypy --config-file ./src/mypy.ini ./src/function

.PHONY: pyformat
pyformat: ## Format Python code
	echo -e $(CYAN)Formatting Python code$(NC)
	$(PYTHON) black -t py38 -l 108 ./src

.PHONY: pytest
pytest: ## Execute Python tests
	echo -e $(CYAN)Executing tests$(NC)
	$(PYTHON) coverage run --branch -m pytest ./src/function -vv --ignore=./src/function/test && \
	$(PYTHON) coverage report --omit="./src/function/test/*" && \
	$(PYTHON) coverage html --title "Function Coverage" -d ./output/coverage/function && \
	$(PYTHON) coverage xml -o ./output/coverage/function/coverage.xml

.PHONY: pypackage
pypackage: ## Package Python code
	echo -e $(CYAN)Packaging Python code$(NC)
	$(PYTHON) ./scripts/package.sh

.PHONY: pyshell
pyshell: ## Shell into Python image
	echo -e $(CYAN)Shelling into Python image$(NC)
	docker-compose run --entrypoint=bash python


##@ Terraform targets
.PHONY: tfformat
tfformat: _validate  ## Format terraform
	echo -e $(CYAN)Formating terraform$(NC)
	$(TERRAFORM) fmt -write=true -recursive

.PHONY: tfvalidate
tfvalidate: _validate ## Validate terraform syntax
	echo -e $(CYAN)Validating terraform$(NC)
	$(TERRAFORM) init -input=false -backend=false
	$(TERRAFORM) validate

.PHONY: tfplan
tfplan: _tfinit ## Generate terraform plan
	echo -e $(CYAN)Planning terraform$(NC)
	$(TERRAFORM) plan $(TF_VARS) -out $(TF_ARTIFACT)

.PHONY: tfapply
tfapply: _validate ## Apply terraform plan
	echo -e $(CYAN)Applying terraform$(NC)
	$(TERRAFORM) apply $(TF_ARTIFACT) && \
	$(TERRAFORM) output -no-color -json > $(TF_OUTPUT)

.PHONY: tfdestroy
tfdestroy: _tfinit ## Destroy infrastructure
	echo -e $(RED)Destroying terraform$(NC)
	$(TERRAFORM) destroy -auto-approve $(TF_VARS)

.PHONY: tfrefresh
tfrefresh: _tfinit ## Refresh terraform state
	echo -e $(CYAN)Refreshing terraform$(NC)
	$(TERRAFORM) refresh $(TF_VARS)


##@ Sonar targets
.PHONY: sonarscan
sonarscan: ## Run sonar scanner
	echo -e $(CYAN)Running sonar scanner$(NC)
	# Hack start - there always seems to be a problem with the first call after the awscli docker image has been downloaded
	docker-compose run -T awscli secretsmanager get-secret-value --secret-id "auth/sonarcloud" --query SecretString &>/dev/null
	# Hack end
	docker-compose run -T awscli secretsmanager get-secret-value --secret-id "auth/sonarcloud" --query SecretString | \
	xargs -I {} $(SONAR) -Dsonar.branch.name=$(GIT_BRANCH) -Dsonar.login={}


##@ Shell targets
.PHONY: awscli
awscli: ## Shell into awscli
	echo -e $(CYAN)Shelling into awscli$(NC)
	docker-compose run --entrypoint=bash awscli

.PHONY: terraform
terraform: ## Shell into terraform
	echo -e $(CYAN)Shelling into terraform$(NC)
	docker-compose run --entrypoint=ash terraform

.PHONY: sonar
sonar: ## Shell into sonar
	echo -e $(CYAN)Shelling into sonar$(NC)
	docker-compose run --entrypoint=ash sonar


##@ Test targets
.PHONY: testapi
testapi: ## Execute api test
	echo -e $(CYAN)Executing api test$(NC)
	# Hack start
	# There seems to be a replication delay between when an ECR password is issued and when it can be used.
	# Added delay between two identical calls to login into ECR. The first always fails and the second succeeds.
	$(AWSCLI) ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin $(HHC_DOCKER_REPO)
	sleep 5
	# Hack end
	$(AWSCLI) ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin $(HHC_DOCKER_REPO)
	docker-compose run -e API_URL=$(TF_OUTPUT_API) -e API_KEY=$(TF_OUTPUT_API_KEY) python tavern-ci --tb=short \
		-W="ignore::pytest.PytestDeprecationWarning" --disable-pytest-warnings ./output/src/function/test -vv


##@ Misc targets
.PHONY: help
help: ## Display this help
	awk \
	  'BEGIN { \
	    FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n" \
	  } /^[a-zA-Z_-]+:.*?##/ { \
	    printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 \
	  } /^##@/ { \
	    printf "\n\033[1m%s\033[0m\n", substr($$0, 5) \
	  } ' $(MAKEFILE_LIST)


##@ Helpers
.PHONY: _tfinit
_tfinit: _validate _clean ## Initialise terraform state
	echo -e $(CYAN)Initialising terraform$(NC)
	$(TERRAFORM) init -input=false \
		-backend-config="key=$(HHC_FUNCTION)/$(HHC_APPLICATION)/$(HHC_ENVIRONMENT)/$(HHC_INSTANCE)/terraform.tfstate" \
		-backend-config="bucket=hhc-terraform-tech-account-infra-$(HHC_ENVIRONMENT)" \
		-backend-config="dynamodb_table=hhc-terraform-tech-account-infra-$(HHC_ENVIRONMENT)" \
		-reconfigure

.PHONY: _clean
_clean: ## Remove terraform directory and docker networks
	echo -e $(CYAN)Removing .terraform directory and docker networks$(NC)
	docker-compose run --entrypoint="rm -rf .terraform" terraform
	docker-compose down --remove-orphans 2>/dev/null

.PHONY: _validate
_validate: ## Validate environment variables
	[[ "$(HHC_ENVIRONMENT)" =~ $(OPT_ENVIRONMENT) ]] || (echo "$(HHC_ENVIRONMENT) is not a valid option" && exit 1)
