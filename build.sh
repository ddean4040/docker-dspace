#!/bin/bash

docker build . -f Dockerfile.builder --tag njsl/dspace-docker:base-5.8
docker build . -f Dockerfile.runner  --tag njsl/dspace-docker:dspace-5.8
