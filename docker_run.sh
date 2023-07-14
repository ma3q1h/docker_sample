#!/bin/bash
# Make work directory if not exist
if [ ! -d ./work ]; then
	mkdir work
fi

USER=$(whoami)
HOST_PORT='8880-8888'
GUEST_PORT='8880-8888'
CONTAINER_NAME='container'
IMAGE_NAME='image'

docker run --gpus all --rm -v `pwd`/work:/home/$USER/work -p $HOST_PORT:$GUEST_PORT --name $CONTAINER_NAME -it $IMAGE_NAME bash
