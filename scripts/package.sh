#!/usr/bin/env bash
set -euo pipefail

rm -rf ./output/src
mkdir -p ./output/src/

cp -r ./src/* ./output/src

# Function
cd ./output/src/function
mv function function_temp
mkdir -p ./function
mv function_temp function/function

pip3 install --upgrade --target ./function \
    falcon \
    serverless-wsgi \
    requests \
    prance

cd ../../../
