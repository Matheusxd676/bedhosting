#!/bin/bash

# Atualize o sistema operacional
sudo apt update
sudo apt upgrade -y

# Instale as dependências necessárias
sudo apt install -y curl software-properties-common zip unzip

# Adicione o repositório do PHP 8.2
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update

# Instale o PHP 8.2 e extensões necessárias
sudo apt install -y php8.2 php8.2-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip}

# Instale o MySQL Server
sudo apt install -y mysql-server

# Configurar o MySQL
sudo mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE panel;
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'FWEIDNWOIA3@#@10c';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Instale o Redis Server
sudo apt install -y redis-server

# Configure o Redis
sudo sed -i "s/^supervised no/supervised systemd/" /etc/redis/redis.conf
sudo sed -i "s/^# requirepass foobared/requirepass MDIWANDI9231#@1/" /etc/redis/redis.conf
sudo systemctl restart redis.service

# Baixe o painel Pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v1.11.3/panel.tar.gz
mkdir -p /var/www/pterodactyl
tar --strip-components=1 -xzvf panel.tar.gz -C /var/www/pterodactyl
cd /var/www/pterodactyl

# Instale o Composer e as dependências do Pterodactyl
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
cp .env.example .env
composer install --no-dev --optimize-autoloader

# Configure o painel Pterodactyl
php artisan key:generate --force
php artisan p:environment:setup --n --url=\$SERVER_IP --timezone=America/Sao_Paulo --cache=redis --session=database --queue=redis --redis-host=127.0.0.1 --redis-pass=MDIWANDI9231#@1
php artisan p:environment:database --n --host=127.0.0.1 --port=3306 --database=panel --username=pterodactyl --password=FWEIDNWOIA3@#@10c
php artisan migrate --seed --force
php artisan p:user:make --n --admin=1 --email=admin@admin.com --username=admin --name-first=nome1 --name-last=nome2 --password=admin

## Continuação do script

```bash
# Configure o NGINX
cat <<EOF > /etc/nginx/sites-available/pterodactyl.conf
server_tokens off;
server_name _;
root /var/www/pterodactyl/public;
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
location ~ \.php$ {
    try_files $uri =404;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param HTTP_PROXY "";
}
location ~ /\.ht {
    deny all;
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# Configure as permissões do Pterodactyl
chown -R www-data:www-data /var/www/pterodactyl/*
chmod -R 755 /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache/

# Adicione o cronjob do Pterodactyl
echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1" | sudo crontab -u www-data -

# Reinicie os serviços
systemctl restart nginx
systemctl restart php8.2-fpm

# O painel Pterodactyl agora deve estar disponível e configurado!
echo "A instalação do painel Pterodactyl foi concluída. Por favor, acesse o painel através do seu navegador."
