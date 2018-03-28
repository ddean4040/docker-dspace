#!/bin/bash

docker image tag njsl/dspace-docker:dspace-5.8 coderegistry.jerseyconnect.net/njsl/dspace-docker:dspace-5.8
docker push coderegistry.jerseyconnect.net/njsl/dspace-docker:dspace-5.8

