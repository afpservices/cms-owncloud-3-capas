# cms-owncloud-3-capas

## Índice

1. [Introducción](#introducción) 
2. [Direccionamiento IP](#direccionamiento-ip)  
3. [Infraestructura](#infraestructura)  
   - [Capa 1: Balanceador de carga](#capa-1-balanceador-de-carga)  
   - [Capa 2: BackEnd](#capa-2-backend)  
   - [Capa 3: Datos](#capa-3-datos)  

---

## Introducción

-Este proyecto tiene como objetivo desplegar un cms en 3 capas la cual ira compuesta con ficheros de aprovisionamientos los cuales una será del balanceador(capa1), Bakcends + NFS (capa2),Base de datos(capa3).

## Direccionamiento IP
El direccionamiento IP de las máquinas se organizará dentro de la subred `192.168.56.0/24` para facilitar la comunicación local.  
- **192.168.53.2:** Balanceador de carga.  
- **192.168.53.3 - 192.168.53.4:** Servidores web backend.  
- **192.168.53.5:** Servidor NFS + PHP-FPM.  
- **192.168.53.6:** Servidor de base de datos MariaDB.  

## Infraestructura

La arquitectura se diseñará con la siguiente estructura y direccionamiento IP:

### Capa 1: Balanceador de carga
- Una máquina con Nginx configurada como balanceador de carga, expuesta a la red pública.  
  - **Nombre de la máquina:** `balanceadorfelipe`  
  - **IP:** `192.168.53.3`
 
  - Script de aprovisionamiento del balanceador:
 

```bash
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

```
### Capa 2: BackEnd
- Dos servidores web Nginx que manejarán las peticiones balanceadas.  
  - **Nombre de las máquinas:** `serverweb1felipe` y `serverweb2felipe`  
  - **IP:** `192.168.53.3` y `192.168.53.4`
 
  - Script de aprovisionamiento backend:
 
    ```bash

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
    ```
- Una máquina con servidor NFS para compartir los datos del CMS y un motor PHP-FPM para el procesamiento de las peticiones PHP.  
  - **Nombre de la máquina:** `servernfsfelipe`  
  - **IP:** `192.168.53.5`

- Script de aprovisionamiento del nfs:

```bash
#!/bin/bash
# Instalar NFS Server y dependencias
sudo apt-get update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt-get install -y nfs-kernel-server php7.4 php7.4-fpm php7.4-mysql php7.4-xml php7.4-mbstring php7.4-curl php7.4-gd php7.4-zip 
sudo apt install php7.4-intl
sudo phpenmod intl
sudo apt install unzip

# Crear directorio compartido
mkdir -p /var/nfs/shared/owncloud
sudo chown -R nobody:nogroup /var/nfs/shared
sudo chmod -R 777 /var/nfs/shared

# Configurar exportaciones
echo "/var/nfs/shared 192.168.53.3/24(rw,sync,no_subtree_check)" >> /etc/exports
echo "/var/nfs/shared 192.168.53.4/24(rw,sync,no_subtree_check)" >> /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server

# Descargar ownCloud
sudo wget https://download.owncloud.com/server/stable/owncloud-complete-latest.zip
sudo mkdir -p /var/nfs/shared/tmp/
sudo unzip owncloud-complete-latest.zip -d /var/nfs/shared/tmp
sudo mv /var/nfs/shared/tmp/* /var/nfs/shared/
sudo rm -rf /var/nfs/shared/tmp
sudo chown -R www-data:www-data /var/nfs/shared/




```
### Capa 3: Datos
- Una máquina con base de datos MariaDB.  
  - **Nombre de la máquina:** `bbddfelipe`  
  - **IP:** `192.168.53.6`

-fichero de aprovisionamiento base de datos:
```bash

sudo apt install mysql-server -y
sudo apt update -y
sudo apt install -y mysql-server
sed -i "s/^bind-address\s*=.*/bind-address = 192.168.53.6/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

mysql <<EOF
CREATE DATABASE db_owncloud;
CREATE USER 'felipe'@'192.168.53.%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON db_owncloud.* TO 'felipe'@'192.168.53.%';
FLUSH PRIVILEGES;
EOF
```



