#!/bin/bash
set -euo pipefail

buildkite-agent artifact download src.tar.gz .
tar -zxf src.tar.gz

buildkite-agent artifact download "infra/*.json" infra/ --step "${DEPLOY_STEP}"

make test
