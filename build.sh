#!/bin/bash

VER=${1:-5.8}

docker build . -f Dockerfile.builder --build-arg DSPACE_VERSION=$VER --tag njsl/dspace-docker:base-$VER
docker build . -f Dockerfile.runner  --build-arg DSPACE_VERSION=$VER --tag njsl/dspace-docker:dspace-$VER
