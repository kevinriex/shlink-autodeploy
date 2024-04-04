#!/bin/bash

# 1. install nessesary tools

apt-get update
apt-get upgrade -y
apt-get install nano curl sudo pwgen

# 2. add user
username=dude
userpasswd=$(pwgen -y -c -n -s 24 1)
/sbin/useradd -m -p '${userpasswd}' ${username} /bin/bash

# n-1 print passwd for user
echo "The new user is " ${username} "identified by: ${userpasswd}"