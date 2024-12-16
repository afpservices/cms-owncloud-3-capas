#!/bin/bash
# Instalar Nginx
sudo apt-get update
sudo apt-get install -y nginx

# Configuramos Nginx como balanceador
cat <<EOF > /etc/nginx/sites-available/loadbalancer
upstream webservers {
    server 192.168.53.3;
    server 192.168.53.4;
}

server {
    listen 80;
    server_name loclahost;

    location / {
        proxy_pass http://webservers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/loadbalancer /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx