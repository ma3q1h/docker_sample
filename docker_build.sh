#!/bin/bash
USER=$(whoami)
UID=$(id -u)
GID=$(id -g)
IMAGE_NAME='image'

# build the image
docker build ./ --build-arg USERNAME=$USER --build-arg USER_ID=$UID --build-arg GROUP_ID=$GID -t $IMAGE_NAME