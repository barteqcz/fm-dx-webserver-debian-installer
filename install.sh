#/bin/bash

clear
read -rp "Please provide password for xdrd (default: password): " $xdrd_password
read -rp "Please provide the used serial port path (default: /dev/ttyUSB0): " $xdrd_serial_port

if [[ $xdrd_password == "" ]]; then
    xdrd_password="password"
fi

if [[ $xdrd_serial_port == "" ]]; then
    xdrd_serial_port="/dev/ttyUSB0"
fi

user=$(whoami)

sudo -i

mkdir build
cd build

build_dir=$(pwd)

apt install git -y
git clone https://github.com/kkonradpl/xdrd.git
apt install libssl-dev pkgconf -y
cd xdrd/
make
make install
usermod -aG dialout $user

echo "[Unit] \
Description=xdrd \
After=network-online.target \
Wants=network-online.target \
\
[Service] \
ExecStart=/usr/bin/xdrd -s $xdrd_serial_port -p $xdrd_password \
User=$user \
Restart=always \
StandardOutput=syslog \
StandardError=syslog \
SyslogIdentifier=xdrd \
\
[Install] \
WantedBy=multi-user.target" > /etc/systemd/system/xdrd.service

chmod 644 /etc/systemd/system/xdrd.service
systemctl daemon-reload
systemctl start xdrd
systemctl enable xdrd

cd $build_dir
git clone https://github.com/NoobishSVK/fm-dx-webserver.git
apt install ffmpeg nodejs npm -y
npm install

addgroup $user audio
newgrp audio

echo "[Unit] \
Description=FM-DX Webserver \
After=network-online.target xdrd.service \
Requires=xdrd.service \
\
[Service] \
ExecStart=npm run webserver \
WorkingDirectory=$build_dir/fm-dx-webserver \
User=$user \
Restart=always \
StandardOutput=syslog \
StandardError=syslog \
SyslogIdentifier=fm-dx-webserver \
\
[Install] \
WantedBy=multi-user.target" > /etc/systemd/system/fm-dx-webserver.service

chmod 644 /etc/systemd/system/fm-dx-webserver.service
systemctl daemon-reload
systemctl start fm-dx-webserver
systemctl enable fm-dx-webserver

clear
echo "Installation process finished. Check http://localhost:8080 in your browser."
exit