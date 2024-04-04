#!/bin/bash

# 1. install nessesary tools

apt-get update
apt-get upgrade -y
apt-get install nano curl sudo pwgen ca-certificates -y


# 2. add user

username="dude"
userpasswd=$(pwgen -y -c -n -s 24 1)

/sbin/useradd -m -p $(openssl passwd -1 $userpasswd) -s /bin/bash ${username} 
/sbin/usermod -aG sudo $username


# 3. install docker-cd
# docs: https://docs.docker.com/engine/install/debian/

# gpg key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# add source-repo to sources.list
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

# install
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# install docker-compose
curl -L "https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose




# n-1 print passwd for user
echo "The new user is " $username "identified by: ${userpasswd}"