#!/usr/bin/env bash
export DOCKER_BUILDKIT=1
docker build --rm -t haakco/postfix-relay .
