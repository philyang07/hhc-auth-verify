terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.48"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2"
    }
  }
  backend "s3" {
    encrypt = "true"
    region  = "ap-southeast-2"
  }
}

provider "aws" {
  region = "ap-southeast-2"
}
