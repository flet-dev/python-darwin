#!/bin/bash
set -eu

python_version=${1:?}
abis="arm64-apple-ios arm64-apple-ios-simulator x86_64-apple-ios-simulator"

for abi in $abis; do
    ./build-ios-abi.sh $python_version $abi
done