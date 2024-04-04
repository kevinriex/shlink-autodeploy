#!/bin/bash

# 1. install nessesary tools

apt-get update
apt-get upgrade -y
apt-get install nano curl sudo 

# 2. add user
username=dude
userpasswd=$(pwgen -y -c -n -s 24 1)
/sbin/useradd -m -p ${userpasswd} ${username}

# n-1 print passwd for user