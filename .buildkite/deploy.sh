#!/bin/bash
set -euo pipefail

buildkite-agent artifact download src.tar.gz .
tar -zxf src.tar.gz

make deploy

buildkite-agent artifact upload "infra/*.json"
