#!/bin/bash

# Informações do MySQL
read -p "Digite o nome da tabela MySQL que você gostaria de usar: " db_table
read -p "Digite o nome do usuário MySQL: " db_user
read -s -p "Digite a senha do usuário MySQL: " db_pass
echo

# Informações do painel Pterodactyl
read -p "Digite o nome de usuário para o painel Pterodactyl: " ptero_user
read -p "Digite o email para o painel Pterodactyl: " ptero_email
read -p "Digite o nome para o painel Pterodactyl: " ptero_fname
read -p "Digite o sobrenome para o painel Pterodactyl: " ptero_lname
read -s -p "Digite a senha para o painel Pterodactyl: " ptero_pass
echo

# Atualizar o sistema
sudo apt update
sudo apt upgrade -y

# Adicione o comando "add-apt-repository" 
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg

# Adicionar repositórios adicionais para PHP, Redis e MariaDB
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

# Adicionar repositório APT oficial do Redis
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

# O script de configuração do repositório MariaDB pode ser ignorado no Ubuntu 22.04
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Atualizar os repositórios
apt update

# Adicione o repositório universe se você estiver no Ubuntu 18.04
apt-add-repository universe

# Instalar dependências
apt -y install php8.1 php8.1-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server

# Instalar composer

echo yes | curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Baixar e criar pastas do painel Pterodactyl

mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl

# Extrair e dar as permissão

curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# Configurar banco de dados
