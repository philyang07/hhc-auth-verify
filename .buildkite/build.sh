#!/bin/bash
set -euo pipefail

make build

tar -zcf src.tar.gz ./output/src/
buildkite-agent artifact upload "src.tar.gz"

tar -zcf coverage.tar.gz ./output/coverage/
buildkite-agent artifact upload "coverage.tar.gz"
