#!/bin/bash

# Script to locally test the github action

docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/app \
  -w /app \
  efrecon/act:v0.2.88 \
  --platform ubuntu-latest=catthehacker/ubuntu:act-latest \
  --secret-file .env --var-file .env \
  -W .github/workflows/scan.yml "$@"
