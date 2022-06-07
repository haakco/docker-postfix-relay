#!/usr/bin/env bash
export BUILD_IMAGE_NAME="${BUILD_IMAGE_NAME}"
export BUILD_IMAGE_TAG="${BUILD_IMAGE_TAG}"
export DOCKER_FILE="${DOCKER_FILE:-"Dockerfile"}"
export EXTRA_FLAG="${EXTRA_FLAG}"

export DOCKER_BUILDKIT=1

echo "Tagged as : ${IMAGE_NAME}"
echo ""
echo ""

#export CACHE_DIR="/tmp/mn-server-test-cache"
#export CACHE_FROM="${CACHE_FROM} --cache-from=type=local,src=${CACHE_DIR}"
export CACHE_FROM="${CACHE_FROM} --cache-from=type=registry,ref=${BUILD_IMAGE_NAME}:buildcache"
#export CACHE_FROM="${CACHE_FROM} --cache-to=type=local,dest=${CACHE_DIR}"
export CACHE_FROM="${CACHE_FROM} --cache-to=type=registry,ref=${BUILD_IMAGE_NAME}:buildcache,mode=max"

#BUILD_TYPE_FLAG=" --load "
BUILD_TYPE_FLAG=" --push "
export BUILD_TYPE_FLAG

export PLATFORM=" --platform  linux/amd64,linux/arm64/v8 "
#export PLATFORM=" --platform  linux/amd64 "
#export PLATFORM=" --platform linux/arm64/v8 "

CMD='docker buildx build '"${PLATFORM}"' '"${BUILD_TYPE_FLAG}"' '"${CACHE_FROM}"' --rm --file '"${DOCKER_FILE}"' -t '"${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG}"' '"${EXTRA_FLAG}"' .'

echo "Build command: ${CMD}"
echo ""
${CMD}
