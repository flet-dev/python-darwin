#!/bin/bash
set -eu

python_version=${1:?}

./build-ios-abi.sh $python_version ios arm64
./build-ios-abi.sh $python_version simulator arm64
./build-ios-abi.sh $python_version simulator x86_64