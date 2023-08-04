#!/bin/bash
set -euo pipefail

buildkite-agent artifact download coverage.tar.gz .
tar -zxf coverage.tar.gz

make scan
