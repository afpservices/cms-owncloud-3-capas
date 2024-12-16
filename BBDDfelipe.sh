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