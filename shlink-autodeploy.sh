#!/bin/bash

# 0. echo cool intro 
echo "##########################################################################"
printf '  /$$$$$$  /$$       /$$ /$$           /$$                                                 /$$                     /$$                     /$$                                                         /$$    
 /$$__  $$| $$      | $$|__/          | $$                                                | $$                    | $$                    | $$                                                        | $$    
| $$  \__/| $$$$$$$ | $$ /$$ /$$$$$$$ | $$   /$$                      /$$$$$$  /$$   /$$ /$$$$$$    /$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$ | $$  /$$$$$$  /$$   /$$ /$$$$$$/$$$$   /$$$$$$  /$$$$$$$  /$$$$$$  
|  $$$$$$ | $$__  $$| $$| $$| $$__  $$| $$  /$$/       /$$$$$$       |____  $$| $$  | $$|_  $$_/   /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$ /$$__  $$| $$  | $$| $$_  $$_  $$ /$$__  $$| $$__  $$|_  $$_/  
 \____  $$| $$  \ $$| $$| $$| $$  \ $$| $$$$$$/       |______/        /$$$$$$$| $$  | $$  | $$    | $$  \ $$| $$  | $$| $$$$$$$$| $$  \ $$| $$| $$  \ $$| $$  | $$| $$ \ $$ \ $$| $$$$$$$$| $$  \ $$  | $$    
 /$$  \ $$| $$  | $$| $$| $$| $$  | $$| $$_  $$                      /$$__  $$| $$  | $$  | $$ /$$| $$  | $$| $$  | $$| $$_____/| $$  | $$| $$| $$  | $$| $$  | $$| $$ | $$ | $$| $$_____/| $$  | $$  | $$ /$$
|  $$$$$$/| $$  | $$| $$| $$| $$  | $$| $$ \  $$                    |  $$$$$$$|  $$$$$$/  |  $$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$$$$$$/| $$|  $$$$$$/|  $$$$$$$| $$ | $$ | $$|  $$$$$$$| $$  | $$  |  $$$$/
 \______/ |__/  |__/|__/|__/|__/  |__/|__/  \__/                     \_______/ \______/    \___/   \______/  \_______/ \_______/| $$____/ |__/ \______/  \____  $$|__/ |__/ |__/ \_______/|__/  |__/   \___/  
                                                                                                                                | $$                     /$$  | $$                                            
                                                                                                                                | $$                    |  $$$$$$/                                            
                                                                                                                                |__/                     \______/                                             '
echo "##########################################################################"

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

# add user to docker group
/sbin/usermod -aG docker $username

# 4. create proxy.docker-network
docker network create -d bridge proxy

# 5. download docker-compose-files
mkdir /storage
echo "script: created /storage"
mkdir /storage/compose
echo "script: created /storage/compose"
mkdir /storage/compose/traefik
mkdir /storage/compose/shlink
mkdir /storage/compose/portainer
echo "script: created /storage/compose/<services>"


chown $username:$username /storage -R


curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/dev/src/shlink/docker-compose.yml" -o /storage/compose/shlink/docker-compose.yml
curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/dev/src/traefik/docker-compose.yml" -o /storage/compose/traefik/docker-compose.yml
curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/dev/src/portainer/docker-compose.yml" -o /storage/compose/portainer/docker-compose.yml

# 6.create configs
mkdir /storage/compose/shlink/data/
touch /storage/compose/shlink/data/servers.json

mkdir /storage/compose/traefik/config
mkdir /storage/compose/traefik/config/certs
touch /storage/compose/traefik/config/certs/acme.json
chmod 600 /storage/compose/traefik/config/certs/acme.json
curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/dev/src/traefik/config/traefik.yaml" -o /storage/compose/traefik/config/traefik.yaml

# 7. start docker-compose
docker-compose -f /storage/compose/portainer/docker-compose.yml up -d
docker-compose -f /storage/compose/shlink/docker-compose.yml up -d 
docker-compose -f /storage/compose/traefik/docker-compose.yml up -d


# 8. configuring web-interface
apikey=$(docker exec -it shlink_master shlink api-key:generate | grep -oP '(?:")(.*)(?:")' | sed 's/"//g')
echo -e "[
  {
    "name": "KGV An der Landwehr",
    "url": "https://kgv-adl.kyrtech.net",
    "apiKey": "$apikey"
  }
]" > /storage/compose/shlink/data/servers.json

# n-1 print passwd for user
echo "The new user is " $username "identified by: ${userpasswd}"