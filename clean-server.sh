#!/bin/bash

# variables
username=dude

# remove packages
apt-get purge pwgen ca-certificates -y 
apt-get autoremove -y

# remove docker-ce
apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin -y
rm -rf /etc/apt/sources.list.d/docker.list
rm -rf /etc/apt/keyrings/docker.asc

# remove docker-compose
rm -rf /user/local/bin/docker-compose

# remove user
/sbin/userdel ${username}
rm -rf /home/dude