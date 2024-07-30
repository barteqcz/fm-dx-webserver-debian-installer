#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then 
    echo "Please run the script with root privileges (e.g. sudo ./install.sh)"
    exit
fi

default_user="$SUDO_USER"
clear

if [[ -z $default_user ]]; then
    read -rp "Please provide your username: " user
else
    read -rp "Please provide your username (default detected: $default_user): " user
fi

if [[ -z $default_user && $user == "" ]]; then
    echo "Error: no username provided."
    exit
fi

read -rp "Please provide password for xdrd (default: password): " xdrd_password
read -rp "Please provide the used serial port path (default: /dev/ttyUSB0): " xdrd_serial_port

if [[ $user == "" ]]; then
    user="$dfeault_user"
fi

if [[ $xdrd_password == "" ]]; then
    xdrd_password="password"
fi

if [[ $xdrd_serial_port == "" ]]; then
    xdrd_serial_port="/dev/ttyUSB0"
fi

mkdir build
cd build

build_dir=$(pwd)

apt update
apt install git make -y
git clone https://github.com/kkonradpl/xdrd.git
apt install libssl-dev pkgconf -y
cd xdrd/
make
make install
usermod -aG dialout $user

echo "[Unit]
Description=xdrd
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/xdrd -s $xdrd_serial_port -p $xdrd_password
User=$user
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=xdrd

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/xdrd.service

chmod 644 /etc/systemd/system/xdrd.service
systemctl daemon-reload
systemctl start xdrd
systemctl enable xdrd

cd $build_dir
git clone https://github.com/NoobishSVK/fm-dx-webserver.git
apt install ffmpeg nodejs npm -y
npm install

usermod -aG audio $user

echo "[Unit]
Description=FM-DX Webserver
After=network-online.target xdrd.service
Requires=xdrd.service

[Service]
ExecStart=npm run webserver
WorkingDirectory=$build_dir/fm-dx-webserver
User=$user
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=fm-dx-webserver

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/fm-dx-webserver.service

chmod 644 /etc/systemd/system/fm-dx-webserver.service
systemctl daemon-reload
systemctl start fm-dx-webserver
systemctl enable fm-dx-webserver

clear
echo "Installation process finished. Check http://localhost:8080 in your browser."
