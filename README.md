# API Lambda Skeleton Repository

## Prerequisites

The following tools and pre-requisites must be available on the machine being used to deploy the base infrastructure to AWS:

- `bash` - 5.1+
- `make` - 4.3+
- `jq` - 1.6+
- [docker](https://docs.docker.com/install/) - 20.10+
- [docker-compose](https://docs.docker.com/compose/install/) - 1.26+
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - 2
- [gh-cli](https://cli.github.com/manual/installation) - 1.4.0+

## Environment

Set permanent instance environmental variable, where `instance_name` could be your name:
```
HHC_INSTANCE=<instance_name>
```

## Authentication

### AWS

When attempting to deploy to AWS, you will need to set AWS credentials with access for a given account, usually `Devel` account.

- Login to [Household Capital AWS SSO](https://hhc.awsapps.com/start)
- Click on `Command line or programmatic access` for a given account
- Copy `Option 2` to your `~/.aws/credentials` to look like this:
```
[default]
aws_access_key_id = <key>
aws_secret_access_key = <secret>
aws_session_token = <token>
```
**IMPORTANT:** Given token will expire after a few hours.

### Github

The following command allows authentication through a web browser or [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) (PAT).
```shell
gh auth login
```
For further details check the [documentation](https://cli.github.com/manual/gh_auth_login).

## Usage

Clone this repository and follow these steps:

- Navigate to the cloned repo 
- Begin initialisation 
```shell
bash init_lang.sh
```
- Follow the prompts 
```shell
Which programming language? (python/go): python
What is the business function? loan
What is your application name? calculator
```

If you require more than one descriptor for application name use lowercase i.e. `calculatorinstance`

## Description

Skeleton repository for starting a new API Gateway and Lambda serverless repository.<br>
The initialisation script will perform the following:

- Rename the repository folder to `hhc-auth-verify`, i.e. `hhc-loan-calculator`
- Delete the pre-existing `.git` folder and re-initialise
- Search and replace `auth` with the name of the business function, i.e. `loan`
- Search and replace `Auth` with the name of the business function, i.e. `Loan`
- Search and replace `verify` with the name of you application, i.e. `calculator`
- Search and replace `Verify` with the name of you Application, i.e. `Calculator`
- Set `hashicorp/terraform` image to the latest version in `docker-compose.yml`
- Add your `auth-verify` repository to ECR at [hhc-aws-account-infra](https://github.com/household-capital/hhc-aws-account-infra/blob/master/infra/docker.tf)
- Run `make build deploy test destroy`
- Create a new repository on Github under the name `hhc-auth-verify`, i.e. `hhc-loan-calculator`
- Delete this `README.md`, and rename `README_skeleton.md` to `README.md`