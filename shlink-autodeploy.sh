#!/bin/bash

# Variable sets the branch | options: main/ dev/
branch="main/"

# Function to print intro
print_intro() {
    echo "##########################################################################"
    printf '
  /$$$$$$  /$$       /$$ /$$           /$$                                                 /$$                     /$$                     /$$                                                         /$$    
 /$$__  $$| $$      | $$|__/          | $$                                                | $$                    | $$                    | $$                                                        | $$    
| $$  \__/| $$$$$$$ | $$ /$$ /$$$$$$$ | $$   /$$                      /$$$$$$  /$$   /$$ /$$$$$$    /$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$ | $$  /$$$$$$  /$$   /$$ /$$$$$$/$$$$   /$$$$$$  /$$$$$$$  /$$$$$$  
|  $$$$$$ | $$__  $$| $$| $$| $$__  $$| $$  /$$/       /$$$$$$       |____  $$| $$  | $$|_  $$_/   /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$ /$$__  $$| $$  | $$| $$_  $$_  $$ /$$__  $$| $$__  $$|_  $$_/  
 \____  $$| $$  \ $$| $$| $$| $$  \ $$| $$$$$$/       |______/        /$$$$$$$| $$  | $$  | $$    | $$  \ $$| $$  | $$| $$$$$$$$| $$  \ $$| $$| $$  \ $$| $$  | $$| $$ \ $$ \ $$| $$$$$$$$| $$  \ $$  | $$    
 /$$  \ $$| $$  | $$| $$| $$| $$  | $$| $$_  $$                      /$$__  $$| $$  | $$  | $$ /$$| $$  | $$| $$  | $$| $$_____/| $$  | $$| $$| $$  | $$| $$  | $$| $$ | $$ | $$| $$_____/| $$  | $$  | $$ /$$
|  $$$$$$/| $$  | $$| $$| $$| $$  | $$| $$ \  $$                    |  $$$$$$$|  $$$$$$/  |  $$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$$$$$$/| $$|  $$$$$$/|  $$$$$$$| $$ | $$ | $$|  $$$$$$$| $$  | $$  |  $$$$/
 \______/ |__/  |__/|__/|__/|__/  |__/|__/  \__/                     \_______/ \______/    \___/   \______/  \_______/ \_______/| $$____/ |__/ \______/  \____  $$|__/ |__/ |__/ \_______/|__/  |__/   \___/  
                                                                                                                                | $$                     /$$  | $$                                            
                                                                                                                                | $$                    |  $$$$$$/                                            
                                                                                                                                |__/                     \______/                                             
'
    echo "##########################################################################"
}

# Function to install necessary tools
install_tools() {
    apt-get update
    apt-get upgrade -y
    apt-get install nano curl sudo pwgen ca-certificates -y
}

check_env() {
  # variables file
  envfile='./.env'

  if ! [ -f $envfile ]; 
  then
      echo "Created $envfile"
      echo -e "#!/bin/bash
# Variables for shlink-autodeploy.sh
username=dude
domain=shlink-autodep.kyrtech.net
shlink_name="shlink-autodep.kyrtech.net Links"

# Ctrl + S & Ctrl + X to save and exit (or continue)
" > $envfile
      if ! [ -t 1 ]; then 
        echo "script: automatic modification possible"
        nano -c ./.env
      else 
        echo "script: automatic modifaction not possible"
        echo "script: please edit '.env', then rerun './shlink-autodeploy.sh'"
        curl -s -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}shlink-autodeploy.sh" -o "./shlink-autodeploy.sh"
        chmod +x ./shlink-autodeploy.sh
        exit 0
      fi
  fi
}

# Function to add user
add_user() {
    userpasswd=$(pwgen -y -c -n -s 24 1)

    /sbin/useradd -m -p $(openssl passwd -1 $userpasswd) -s /bin/bash ${username} 
    /sbin/usermod -aG sudo $username
}

# Function to install docker and docker-compose
install_docker() {
    # Add Docker GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository to sources.list
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update

    # Install Docker
    apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Add user to docker group
    /sbin/usermod -aG docker $username
}

# Function to create necessary directories and download docker-compose files
prepare_environment() {
    mkdir /storage
    echo "script: created /storage"
    mkdir /storage/compose
    echo "script: created /storage/compose"
    mkdir /storage/compose/traefik
    mkdir /storage/compose/shlink
    mkdir /storage/compose/portainer
    echo "script: created /storage/compose/<services>"

    chown $username:$username /storage -R

    # Download docker-compose files
    curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}src/shlink/docker-compose.yml" -o /storage/compose/shlink/docker-compose.yml
    curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}src/traefik/docker-compose.yml" -o /storage/compose/traefik/docker-compose.yml
    curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}src/portainer/docker-compose.yml" -o /storage/compose/portainer/docker-compose.yml
}

# Function to write variables into configs
parse_variables() {
  sed -i "s/{{DOMAIN}}/$domain/g" /storage/compose/traefik/docker-compose.yml
  sed -i "s/{{DOMAIN}}/$domain/g" /storage/compose/shlink/docker-compose.yml
  sed -i "s/{{DOMAIN}}/$domain/g" /storage/compose/portainer/docker-compose.yml
}

# Function to create configurations
create_configs() {
    # Create Shlink configurations
    mkdir /storage/compose/shlink/data/
    touch /storage/compose/shlink/data/servers.json

    # Create Traefik configurations
    mkdir /storage/compose/traefik/config
    mkdir /storage/compose/traefik/config/certs
    touch /storage/compose/traefik/config/certs/acme.json
    chmod 600 /storage/compose/traefik/config/certs/acme.json
    curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}src/traefik/config/traefik.yaml" -o /storage/compose/traefik/config/traefik.yaml
}

# Function to create docker network 
create_docker_network() {
  docker network create -d bridge proxy
}

# Function to start docker-compose services
start_services() {
    docker-compose -f /storage/compose/portainer/docker-compose.yml up -d
    docker-compose -f /storage/compose/shlink/docker-compose.yml up -d
    docker-compose -f /storage/compose/traefik/docker-compose.yml up -d
}

# Function to configure web interface
configure_web_interface() {
    echo "script: configure web ui! It may take a while..."
    sleep 10
    docker stop shlink_web
    apikey=$(docker exec -it shlink_master shlink api-key:generate | grep -oP '(?:")(.*)(?:")' | sed 's/"//g')
    echo $apikey
    echo -e "[
  {  
  \"name\": \"Shlink-Autodeploy\", 
  \"url\": \"https://shlink-autodep.kyrtech.net\",
  \"apiKey\": \"$apikey\"
  }
]" > /storage/compose/shlink/data/servers.json
    docker start shlink_web
}

# Function to print user's password
print_user_password() {
    echo "The new user is $username identified by: ${userpasswd}"
}

# Function removes file if downloaded
remove_script() {
  if  [ -f ./shlink-autodeploy.sh ]; 
  then
      rm ./shlink-autodeploy.sh
  fi
}

# Main function
main() {
    print_intro
    install_tools
    check_env
    
    echo "Reading variables from $envfile"
    source $envfile
    
    add_user
    install_docker
    prepare_environment
    parse_variables
    create_configs
    create_docker_network
    start_services
    configure_web_interface
    print_user_password
    remove_script
}

# Execute the main function
main