# cms-owncloud-3-capas-felipe

!!!Antes de empezar, owncloud en la comprobacion se me queda colgado pero anteriormente me habia accedido correctamente a la carpeta de configuracion del mismo !!!



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

```
- Para la realizacion de la configuracion del balanceador he de instalar nginx anteriormente, ademas de configurar el fichero del balanceador, el cual he creado en /etc/nginx/sites-available/ y lo he configurado para que en el balanceo de carga funcione correctamente con los servidores:

  ![image](https://github.com/user-attachments/assets/483a05b8-9ca2-4265-a35b-3e5de74b2289)

-Luego una vez configurado todo procedemos a crear un enlace el cual hara una copia exacta de la configuracion que hemos realizado antes y la enrutaremos hacia sites-enabled para activarla y eliminamos la que viene ppor defecto 

![image](https://github.com/user-attachments/assets/30b082fa-0195-42a4-b83f-2878c62af84e)

Eliminamos default
![image](https://github.com/user-attachments/assets/3eb38e27-6c6b-486d-859c-cbf523da1aa3)

Reiniciamos nginx

![image](https://github.com/user-attachments/assets/427ae6d0-c208-4d75-b9b9-1a3a0d53c8cd)


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
Para ello he de instalar php, ademas he creado la carpeta que vamos a compartir y dado permisos a cierta carpeta, ademas de configurar el fichero /etc/fstab

![image](https://github.com/user-attachments/assets/1028cc0f-d6f8-4dba-ae6b-64ef525d2d02)

-Ademas hemos configurado el archivo de owncloud de sites-available 

![image](https://github.com/user-attachments/assets/4e7817ab-1849-4257-b5b9-25fe1fc67daa)


- Una máquina con servidor NFS para compartir los datos del CMS y un motor PHP-FPM para el procesamiento de las peticiones PHP.  
  - **Nombre de la máquina:** `servernfsfelipe`  
  - **IP:** `192.168.53.5`

- Script de aprovisionamiento del nfs:

```bash
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




```

-Para ello hemos creado la carpeta de compartido y dado los permisos necesarios 

![image](https://github.com/user-attachments/assets/5fd5faa8-e6f3-4aa1-a7a9-df5fe514769d)

-Ademas de configurar los archivos de /etc/exports

![image](https://github.com/user-attachments/assets/9f846364-c02b-45ff-8442-b5faaf599a69)


### Capa 3: Base de Datos
- Una máquina con base de datos MariaDB.  
  - **Nombre de la máquina:** `bbddfelipe`  
  - **IP:** `192.168.53.6`

-fichero de aprovisionamiento base de datos:
```bash
#Instalacion de mysql
sudo apt install mysql-server -y
sudo apt update -y
sudo apt install -y mysql-server

#Establecer el bind address de nuestra maquina de mysql en el archivo de configfuracion #de mysql
sed -i "s/^bind-address\s*=.*/bind-address = 192.168.53.6/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

#Creacion de la base de datos 
mysql <<EOF
CREATE DATABASE db_owncloud;
CREATE USER 'felipe'@'192.168.53.%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON db_owncloud.* TO 'felipe'@'192.168.53.%';
FLUSH PRIVILEGES;
EOF
```
- Para ello hemos intalador mysql y hemos asingado el bind-address en el archivo de configuracion de mysqld.cnf

![image](https://github.com/user-attachments/assets/2946a6ec-596b-4972-b3bb-bdc8683db192)


- Ademas hemos creado la base de datos con nuestro usuario 

![image](https://github.com/user-attachments/assets/636b13eb-cc3e-48bc-bf26-6be386a696cf)


