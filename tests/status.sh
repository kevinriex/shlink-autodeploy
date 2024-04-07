#!/bin/bash

a() {
    #whiptail --title "Test script" --inputbox "E-Mail (for letsenrypt):" 8 100 "admin@example.com"
    sleep 2
}
b() {
    sleep 2
}
c() {
    sleep 2
}
d() {
    sleep 2
}
e() {
    sleep 2
}
f() {
    sleep 2
}
max=6
main() {
    a && echo "scale=2; 1/$max*100" | bc | awk -F"." '{print $1}'
    b && echo "scale=2; 2/$max*100" | bc | awk -F"." '{print $1}'
    c && echo "scale=2; 3/$max*100" | bc | awk -F"." '{print $1}'
    d && echo "scale=2; 4/$max*100" | bc | awk -F"." '{print $1}'
    e && echo "scale=2; 5/$max*100" | bc | awk -F"." '{print $1}'
    f && echo "scale=2; 6/$max*100" | bc | awk -F"." '{print $1}'
}

if (whiptail --title "Test script" --yesno "Start installation?" 8 100); then
    main | whiptail --title 'Test script' --gauge 'Running...' 8 100 0
else
    exit 0
fi
whiptail --title "Test script" --msgbox "Installation complete :)" 8 100
