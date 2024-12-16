# Instalar dependencias
sudo apt-get update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt-get install -y nginx php7.4 php7.4-fpm php7.4-mysql php7.4-xml php7.4-mbstring php7.4-curl php7.4-gd php7.4-zip nfs-common
sudo apt install php7.4-intl
sudo phpenmod intl
sudo systemctl restart nginx
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php


# Montar NFS
mkdir -p /var/www/html/owncloud
sudo chown -R www-data:www-data /var/www/html/owncloud
sudo chmod 755 /var/www/html/owncloud
echo "192.168.53.5:/var/nfs/shared/owncloud /var/www/html/owncloud nfs defaults 0 0" >> /etc/fstab
sudo mount -a

# Configurar Nginx para ownCloud
cat <<EOF > /etc/nginx/sites-available/owncloud
server {
    listen 80;
    server_name localhost;

    root /var/www/html/owncloud;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

     location ~ /\.ht {
        deny all;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/owncloud /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx.service