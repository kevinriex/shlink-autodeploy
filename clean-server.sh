#!/bin/bash

# variables
username=dude

# remove user
/sbin/userdel ${username}
rm -rf /home/dude