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
pip3 install Flask Flask-SocketIO

echo 'Web UI username'
read -p '> ' webuser
echo 'Web UI password'
read -p -s '> ' webpass

echo "[Unit]" > /lib/systemd/system/ttyd.service
echo "Description=ttyd" >> /lib/systemd/system/ttyd.service
echo "After=network.target remote-fs.target nss-lookup.target" >> /lib/systemd/system/ttyd.service

echo "[Service]" >> /lib/systemd/system/ttyd.service
echo "ExecStart=ttyd -p 8888 -c $webuser:$webpass reverse" >> /lib/systemd/system/ttyd.service

echo "[Install]"
echo "WantedBy=multi-user.target" >> /lib/systemd/system/ttyd.service

sudo systemctl start ttyd
sudo systemctl enable ttyd

cat << 'EOF' > /etc/nginx/sites-available/download_rclient
server {
    listen 8444;
    server_name _;
    root /usr/local/Reverse/html/;
    index index.html index.htm;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
if ! [ -f /etc/nginx/sites-enabled/download_rclient ]; then ln -s /etc/nginx/sites-available/download_rclient /etc/nginx/sites-enabled/download_rclient; fi

if [ -d /usr/local/Reverse ]; then cd /usr/local/Reverse; else mkdir /usr/local/Reverse && cd /usr/local/Reverse; fi
if ! [ -d /usr/local/Reverse/html ]; then mkdir /usr/local/Reverse/html; fi
chmod +x /usr/local/Reverse/reverse.sh
ln -s "/usr/local/Reverse/reverse.sh" "/bin/reverse/"
echo "<meta http-equiv=\"refresh\" content=\"0; url='./client.py'\" />" > /usr/local/Reverse/html/index.html
if [ -f /usr/local/Reverse/server.py ]; then rm /usr/local/Reverse/server.py; fi
wget https://raw.githubusercontent.com/colbychittenden/Reverse/main/server.py
if [ -f /usr/local/Reverse/client.py ]; then rm /usr/local/Reverse/client.py; fi
wget https://raw.githubusercontent.com/colbychittenden/Reverse/main/client.py
mv ./client.py ./html/client.py
if [ -f /usr/local/Reverse/reverse.sh ]; then rm /usr/local/Reverse/reverse.sh; fi
wget https://raw.githubusercontent.com/colbychittenden/Reverse/main/reverse.sh
if [ "$isoncloud" == 'yes' ]; then
  echo Enter Public IPv4 DNS
  read -p '> ' ipv4dns
  echo $ipv4dns | xargs -I {} sed -i "s/127.0.0.1/{}/g" server.py
  echo $ipv4dns | xargs -I {} sed -i "s/127.0.0.1/{}/g" ./html/client.py
else
  curl -s icanhazip.com | xargs -I {} sed -i "s/127.0.0.1/{}/g" server.py
  curl -s icanhazip.com | xargs -I {} sed -i "s/127.0.0.1/{}/g" ./html/client.py
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
echo Congratulations, Reverse has been successfully installed!
if [ "$isoncloud" == 'yes' ]; then
  echo $ipv4dns | xargs -I {} echo To download your client file visit http://{}:8444
else
  curl -s icanhazip.com | xargs -I {} echo To download your client file visit http://{}:8444
fi
echo
