#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

clear

echo '______                             '
echo '| ___ \                            '
echo '| |_/ /_____   _____ _ __ ___  ___ '
echo '|    // _ \ \ / / _ \ '\''__/ __|/ _ \'
echo '| |\ \  __/\ V /  __/ |  \__ \  __/'
echo '\_| \_\___| \_/ \___|_|  |___/\___|'
echo
echo

ai2=false
dai2=false

while true; do
  if [ "$ai2" == 'false' ]; then
    echo "Are you using AWS? (yes/no)"
    ai2=true
  fi
  read -p '> ' isoncloud

  if [ "$isoncloud" == "yes" ] || [ "$isoncloud" == "no" ]; then
    break 
  else
    echo "Please enter 'yes' or 'no'."
  fi
done

apt update -y
apt install python3 python3-pip screen tmux wget curl nginx certbot python3-certbot-nginx unzip -y
pip3 install Flask Flask-SocketIO webssh

echo "[Unit]" > /etc/systemd/system/webssh.service
echo "Description=WebSSH terminal interface" >> /etc/systemd/system/webssh.service
echo "After=network.target" >> /etc/systemd/system/webssh.service
echo "[Service]" >> /etc/systemd/system/webssh.service
echo "User=www-data" >> /etc/systemd/system/webssh.service
echo "Group=www-data" >> /etc/systemd/system/webssh.service
echo "ExecStart=wssh" >> /etc/systemd/system/webssh.service
echo "[Install]" >> /etc/systemd/system/webssh.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/webssh.service

sudo systemctl start webssh
sudo systemctl enable webssh

echo server { > /etc/nginx/sites-available/download_rclient
echo     listen 8444; >> /etc/nginx/sites-available/download_rclient
echo     server_name _; >> /etc/nginx/sites-available/download_rclient
echo     root /usr/local/Reverse/html/; >> /etc/nginx/sites-available/download_rclient
echo     index index.html index.htm; >> /etc/nginx/sites-available/download_rclient
echo     location / { >> /etc/nginx/sites-available/download_rclient
echo         try_files $uri $uri/ =404; >> /etc/nginx/sites-available/download_rclient
echo     } >> /etc/nginx/sites-available/download_rclient
echo } >> /etc/nginx/sites-available/download_rclient
if ! [ -f /etc/nginx/sites-enabled/download_rclient ]; then ln -s /etc/nginx/sites-available/download_rclient /etc/nginx/sites-enabled/download_rclient; fi

if [ -d /usr/local/Reverse ]; then cd /usr/local/Reverse; else mkdir /usr/local/Reverse && cd /usr/local/Reverse; fi
if ! [ -d /usr/local/Reverse/html ]; then mkdir /usr/local/Reverse/html; fi
echo "alias reverse=\"bash /usr/local/Reverse/reverse.sh\"" >> ~/.bashrc
alias reverse="bash /usr/local/Reverse/reverse.sh"
if [ -f /usr/local/Reverse/server.py ]; then rm /usr/local/Reverse/server.py; fi
wget https://raw.githubusercontent.com/colbychittenden/Reverse/main/server.py
if [ -f /usr/local/Reverse/reverse.sh ]; then rm /usr/local/Reverse/reverse.sh; fi
wget https://raw.githubusercontent.com/colbychittenden/Reverse/main/reverse.sh
if [ "$isoncloud" == 'yes' ]; then
  echo Enter Public IPv4 DNS
  read -p '> ' ipv4dns
  echo $ipv4dns | xargs -I {} sed -i "s/127.0.0.1/{}/g" server.py
else
  curl -s icanhazip.com | xargs -I {} sed -i "s/127.0.0.1/{}/g" server.py
fi

cd /etc/nginx/sites-available/
if [ -f /etc/nginx/sites-available/webssh ]; then rm /etc/nginx/sites-available/webssh; fi
wget -O webssh https://raw.githubusercontent.com/colbychittenden/Reverse/main/webssh-nginx.conf
if ! [ -f /etc/nginx/sites-enabled/webssh ]; then ln -s /etc/nginx/sites-available/webssh /etc/nginx/sites-enabled/webssh; fi
if [ -f /etc/nginx/sites-enabled/default ]; then rm /etc/nginx/sites-enabled/default; fi
systemctl restart nginx

while true; do
  if [ "$dai2" == 'false' ]; then
    echo "Would you like to set up a custom domain? (yes/no)"
    dai2=true
  fi
  read -p '> ' domainenabled

  if [ "$domainenabled" == "yes" ] || [ "$domainenabled" == "no" ]; then
    break 
  else
    echo "Please enter 'yes' or 'no'."
  fi
done

if [ "$domainenabled" == "yes" ]; then
  echo 'Email (for certbot updates)'
  read -p '> ' useremail
  echo 'Domain name (MUST have an A/AAAA record pointing to public ip)'
  read -p '> ' userdomain
  echo $userdomain | xargs -I {} sed -i "s/your_domain/{}/g" /etc/nginx/sites-available/webssh
  certbot --nginx --agree-tos --no-eff-email --email $useremail -d $userdomain
fi
clear
