#!/bin/bash

# constants
export MINECRAFT_FILE_SYSTEM_ID="fs-c154276b"
export SPIGOT_VERSION="1.15.2" # should correspond to minecraft version
export AWS_REGION="us-west-2"

# update and install docker
# NOTE, -y makes yum answer yes to all prompts
sudo yum update -y
sudo yum -y install docker
sudo service docker start
sudo usermod -a -G docker ec2-user # allow ec2-user to use docker commands

# mount the network file system where the minecraft files are kept
sudo yum install -y amazon-efs-utils
sudo mkdir /
sudo mkdir efs
sudo mount -t efs "$MINECRAFT_FILE_SYSTEM_ID":/ efs/
cd efs

# create a minecraft-server folder if not exists
[[ -d minecraft-server ]] || mkdir minecraft-server
cd minecraft-server

# run docker command to start server
# docker image github: https://github.com/nimmis/docker-spigot
sudo docker run -d \
    --name minecraft \
    -p 25565:25565 \
    -p 25575:25575 \
    -p 8123:8123 \
    -e EULA=true \
    -e MC_MINMEM=1g \
    -e MC_MAXMEM=7g \
    -v "$PWD":/minecraft \
    -e SPIGOT_VER="$SPIGOT_VERSION" nimmis/spigot

# run this command to unmount the file system before shutting off the instance
# cd ~ && umount efs # not a typo: command is umount


