#!/bin/bash

echo "Starting server cleaning process..."

# variables
username=dude
envfile=./.env

# stop docker-compose
docker ps -aq | xargs docker stop | xargs docker rm
# docker-compose down -f /storage/compose/portainer/docker-compose.yml
# docker-compose down -f /storage/compose/traefik/docker-compose.yml
# docker-compose down -f /storage/compose/shlink/docker-compose.yml

# remove docker-network
docker network rm proxy

# remove /storage
rm -rf /storage

# remove docker-compose
rm -rf /user/local/bin/docker-compose

# remove docker-ce
apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin -y
rm -rf /etc/apt/sources.list.d/docker.list
rm -rf /etc/apt/keyrings/docker.asc


# remove user
/sbin/userdel ${username}
rm -rf /home/dude

# remove packages
apt-get purge pwgen -y 
apt-get autoremove -y

rm $envfile