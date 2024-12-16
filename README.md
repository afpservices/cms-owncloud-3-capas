# cms-owncloud-3-capas


# Introducción

En este proyecto se desplegará un CMS (a elegir entre OwnCloud o Joomla) sobre una infraestructura en alta disponibilidad basada en la pila LEMP (Linux, Nginx, MariaDB, PHP). La infraestructura estará dividida en tres capas, asegurando una separación lógica entre balanceo de carga, servidores backend y la base de datos. El despliegue se realizará en un entorno local utilizando **Vagrant** y **VirtualBox**, y el aprovisionamiento de cada máquina se automatizará mediante scripts de provisionamiento.

## Infraestructura

La arquitectura se diseñará con la siguiente estructura y direccionamiento IP:

### Capa 1: Balanceador de carga
- Una máquina con Nginx configurada como balanceador de carga, expuesta a la red pública.  
  - **Nombre de la máquina:** `balanceadorfelipe`  
  - **IP:** `192.168.53.3`

### Capa 2: BackEnd
- Dos servidores web Nginx que manejarán las peticiones balanceadas.  
  - **Nombre de las máquinas:** `serverweb1felipe` y `serverweb2felipe`  
  - **IP:** `192.168.53.3` y `192.168.53.4`  
- Una máquina con servidor NFS para compartir los datos del CMS y un motor PHP-FPM para el procesamiento de las peticiones PHP.  
  - **Nombre de la máquina:** `servernfsfelipe`  
  - **IP:** `192.168.53.5`

### Capa 3: Datos
- Una máquina con base de datos MariaDB.  
  - **Nombre de la máquina:** `bbddfelipe`  
  - **IP:** `192.168.53.6`

### Esquema de Conexiones
- El balanceador de carga en la capa 1 será el único punto de acceso público y redirigirá el tráfico hacia los servidores de la capa 2.  
- Los servidores web de la capa 2 utilizarán:
  - Un directorio compartido mediante NFS desde `serverNFSTuNombre` para alojar los archivos del CMS.  
  - El motor PHP-FPM instalado en `serverNFSTuNombre` para procesar las peticiones PHP.  
- La base de datos en la capa 3 estará accesible únicamente desde los servidores de la capa 2, asegurando que no esté expuesta a la red pública.  

### Direccionamiento IP
El direccionamiento IP de las máquinas se organizará dentro de la subred `192.168.56.0/24` para facilitar la comunicación local.  
- **192.168.53.2:** Balanceador de carga.  
- **192.168.53.3 - 192.168.53.4:** Servidores web backend.  
- **192.168.53.5:** Servidor NFS + PHP-FPM.  
- **192.168.53.6:** Servidor de base de datos MariaDB.  

Este esquema garantiza un diseño modular y escalable, con una separación clara entre las funciones de cada capa y el acceso controlado a los servicios esenciales.  
