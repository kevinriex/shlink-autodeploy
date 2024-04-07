#!/bin/bash

# Variables

branch="dev/" # Variable sets the branch | options: main/ dev/
basepath="/storage/compose"
basicauthpwd=$(pwgen -n -s 12 1)


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
cert_email=certs.admin@me.kevinriex.de
shlink_name="shlink-autodep.kyrtech.net Links"

# Ctrl + S & Ctrl + X to save and exit (or continue)
" > $envfile
      if ! [ -t 1 ]; then 
        echo "script: automatic modification possible"
        nano -c ./.env
      else 
        echo "script: automatic modifaction not possible"
        echo "script: please edit '.env' (e.g. nano .env), then rerun './shlink-autodeploy.sh'"
        curl -s -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}shlink-autodeploy.sh" -o "./shlink-autodeploy.sh"
        chmod +x ./shlink-autodeploy.sh
        exit 0
      fi
  fi
}

# Function to add user
add_user() {
    userpwd=$(pwgen -y -c -n -s 24 1)

    /sbin/useradd -m -p $(openssl passwd -1 $userpwd) -s /bin/bash ${username} 
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
    mkdir $basepath
    echo "script: created $basepath"
    mkdir $basepath/traefik
    mkdir $basepath/shlink
    mkdir $basepath/portainer
    echo "script: created $basepath/<services>"

    chown $username:$username /storage -R

    # Download docker-compose files
    curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}src/shlink/docker-compose.yml" -o $basepath/shlink/docker-compose.yml
    curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}src/traefik/docker-compose.yml" -o $basepath/traefik/docker-compose.yml
    curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}src/portainer/docker-compose.yml" -o $basepath/portainer/docker-compose.yml
}

# Function to write variables into configs
parse_variables() {

  sed -i "s/{{DOMAIN}}/$domain/g" $basepath/traefik/docker-compose.yml
  sed -i "s/{{DOMAIN}}/$domain/g" $basepath/shlink/docker-compose.yml
  sed -i "s/{{DOMAIN}}/$domain/g" $basepath/portainer/docker-compose.yml

  sed -i "s/{{USER}}/$username/g" $basepath/traefik/docker-compose.yml
  sed -i "s/{{USER}}/$username/g" $basepath/shlink/docker-compose.yml
  sed -i "s/{{USER}}/$username/g" $basepath/portainer/docker-compose.yml

  basicauthpwdhash=$(echo $basicauthpwd | htpasswd -nBi $username)

  sed -i "s/{{PASSWORD}}/$basicauthpwdhash/g" $basepath/traefik/docker-compose.yml
  sed -i "s/{{PASSWORD}}/$basicauthpwdhash/g" $basepath/shlink/docker-compose.yml
  sed -i "s/{{PASSWORD}}/$basicauthpwdhash/g" $basepath/portainer/docker-compose.yml
}

# Function to create configurations
create_configs() {
    # Create Shlink configurations
    mkdir $basepath/shlink/data/
    touch $basepath/shlink/data/servers.json

    # Create Traefik configurations
    mkdir $basepath/traefik/config
    mkdir $basepath/traefik/config/certs
    touch $basepath/traefik/config/certs/acme.json
    chmod 600 $basepath/traefik/config/certs/acme.json
    curl -L "https://github.com/kevinriex/shlink-autodeploy/raw/${branch}src/traefik/config/traefik.yaml" -o $basepath/traefik/config/traefik.yaml
    sed -i -e "s/{{E-MAIL}}/$cert_email/g" $basepath/traefik/config/traefik.yaml
}

# Function to create docker network 
create_docker_network() {
  docker network create -d bridge proxy
}

# Function to start docker-compose services
start_services() {
    docker-compose -f $basepath/portainer/docker-compose.yml up -d
    docker-compose -f $basepath/shlink/docker-compose.yml up -d
    docker-compose -f $basepath/traefik/docker-compose.yml up -d
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
  \"url\": \"https://$domain\",
  \"apiKey\": \"$apikey\"
  }
]" > $basepath/shlink/data/servers.json
    docker start shlink_web
}

# Function to print user's password
print_user_password() {
    echo "The new system-user is $username identified by: ${userpwd}"
    echo "The new basic-auth-user is $username identified by: ${basicauthpwd}"
    echo "Please save this information. it will never be shown"
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