# Auth Verify Repository
## Prerequisites

The following tools and pre-requisites must be available on the machine being used to deploy the base infrastructure to AWS:

- `bash` - 5.1+
- `make` - 4.3+
- `jq` - 1.6+
- [docker](https://docs.docker.com/install/) - 20.10+
- [docker-compose](https://docs.docker.com/compose/install/) - 1.26+

## Environment

Set permanent instance environmental variable, where `instance_name` could be your name:
```
HHC_INSTANCE=<instance_name>
```

## New Repositories
If you've created a new repo you must update infra/locals.tf in [hhc-account-infra](https://github.com/household-capital/hhc-aws-account-infra).<br>
Please add your repo to buildkite and ecr collections (use previous commits as a guide) in that file.<br>
Once these changes have been merged into master then visit [Account Infra Pipeline](https://buildkite.com/household-capital/aws-account-infra-master).<br>
If there's an issue with the development env in that pipeline go to ECR service in AWS management<br> 
console and delete the existing docker image.

## Usage

To authenticate with a different AWS account:
```
make authconfig
```
To re-authenticate with the same AWS account:
```
make auth
```
To build and deploy your instance:
```
make build deploy
```
To test your instance:
```
make test
```
To destroy your instance:
```
make destroy
```
For other options:
```
make help
```

## Config-as-Code

- Config files are located in the `config/` directory.

## Infrastructure-as-Code

- The `infra/` directory contains the terraform configuration.
- The `infra/main.tf` file houses the main script.
- The `infra/modules` directory contains the terraform configuration for various aws resources.
- Environment specific variables files are located in the `config/` directory.

## Pipelines-as-Code

The `.buildkite/` directory contains pipeline configurations:

- [Pre pull request pipeline](https://buildkite.com/household-capital/auth-verify-devel)
- [Staging and production pipeline](https://buildkite.com/household-capital/auth-verify-master)

## Static Analysis

The `sonar-project.properties` file contains SonarQube configuration:

- [SonarCloud](https://sonarcloud.io/dashboard?id=household-capital_hhc-auth-verify)
