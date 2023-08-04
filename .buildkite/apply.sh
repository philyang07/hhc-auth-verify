#!/bin/bash
set -euo pipefail

buildkite-agent artifact download src.tar.gz .
tar -zxf src.tar.gz

buildkite-agent artifact download "infra/*.tfplan" infra/ --step "${PLAN_STEP}"
buildkite-agent artifact download "infra/.terraform.lock.hcl" infra/ --step "${PLAN_STEP}"
buildkite-agent artifact download ".terraform.zip" . --step "${PLAN_STEP}"
buildkite-agent artifact download "output/function.zip" output/ --step "${PLAN_STEP}"

unzip -q ./.terraform.zip -d ./infra

make tfapply

buildkite-agent artifact upload "infra/*.json"
