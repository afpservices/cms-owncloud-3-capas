#!/bin/bash
# Instalacion de nfs y de libreria de mysql y php 
sudo apt-get update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt-get install -y nfs-kernel-server php7.4 php7.4-fpm php7.4-mysql php7.4-xml php7.4-mbstring php7.4-curl php7.4-gd php7.4-zip 
sudo apt install php7.4-intl
sudo phpenmod intl
sudo apt install unzip



# Creacion del directorio compartido
mkdir -p /var/nfs/shared/owncloud
sudo chown -R nobody:nogroup /var/nfs/shared
sudo chmod -R 777 /var/nfs/shared

# Configuramos los archivos de /etc/exports
echo "/var/nfs/shared 192.168.53.3/24(rw,sync,no_subtree_check)" >> /etc/exports
echo "/var/nfs/shared 192.168.53.4/24(rw,sync,no_subtree_check)" >> /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server

# Descargamos owncloud
sudo wget https://download.owncloud.com/server/stable/owncloud-complete-latest.zip
sudo mkdir -p /var/nfs/shared/tmp/
sudo unzip owncloud-complete-latest.zip -d /var/nfs/shared/tmp
sudo mv /var/nfs/shared/tmp/* /var/nfs/shared/
sudo rm -rf /var/nfs/shared/tmp
sudo chown -R www-data:www-data /var/nfs/shared/