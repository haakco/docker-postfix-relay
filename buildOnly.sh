#!/usr/bin/env bash
export DOCKER_FILE="./Dockerfile"

SCRIPT_DIR=$(dirname "$0")
export SCRIPT_DIR

## Build args
export BASE_IMAGE_NAME="alpine"
export BASE_IMAGE_TAG="latest"

export BUILD_IMAGE_NAME="ghcr.io/haakco/postfix-relay"
export BUILD_IMAGE_TAG="latest"

EXTRA_FLAG="${EXTRA_FLAG} --build-arg BASE_IMAGE_NAME=${BASE_IMAGE_NAME}"
EXTRA_FLAG="${EXTRA_FLAG} --build-arg BASE_IMAGE_TAG=${BASE_IMAGE_TAG}"
export EXTRA_FLAG

"${SCRIPT_DIR}/baseBuild.sh"
