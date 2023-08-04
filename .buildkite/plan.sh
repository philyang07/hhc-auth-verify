#!/bin/bash
set -euo pipefail

buildkite-agent artifact download src.tar.gz .
tar -zxf src.tar.gz

make tfplan

buildkite-agent artifact upload "infra/*.tfplan"
buildkite-agent artifact upload "infra/.terraform.lock.hcl"

cd ./infra
zip -q -dc -r ../.terraform.zip .terraform/
cd ..

buildkite-agent artifact upload ".terraform.zip"
buildkite-agent artifact upload "output/function.zip"
