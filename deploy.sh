#!/bin/bash

VER=${1:-5.8}

docker image tag njsl/dspace-docker:dspace-$VER coderegistry.jerseyconnect.net/njsl/dspace-docker:dspace-$VER
docker push coderegistry.jerseyconnect.net/njsl/dspace-docker:dspace-$VER