#!/bin/bash

#
## SCRIPT HECHO POR AYUDAKITDIGITAL
### Script de instalación de Odoo15, postgresql, Nginx(sin configurar) y Certbot.
## Versión 0.1
#

# Actualizar el sistema (Preferiblemente hacerlo a mano y reiniciar el servidor antes de ejecutar el script)
# sudo dnf update -y

# Creacion de los usuarios del sistema
sudo useradd -m acarrillo
sudo useradd -m amisis
sudo useradd -m omontero
sudo useradd -m gpuig
sudo useradd -m pgallego
sudo useradd -m jorovengua
sudo useradd -m afornaguera
sudo useradd -m jdelosmozos
sudo useradd -m nasensi
sudo useradd -m nhumet

# Establecer la contraseña para los usuarios
echo "AhD6areifeegh4Ua" | sudo passwd --stdin acarrillo
echo "AhD6areifeegh4Ua" | sudo passwd --stdin amisis
echo "AhD6areifeegh4Ua" | sudo passwd --stdin omontero
echo "AhD6areifeegh4Ua" | sudo passwd --stdin gpuig
echo "AhD6areifeegh4Ua" | sudo passwd --stdin pgallego
echo "AhD6areifeegh4Ua" | sudo passwd --stdin jorovengua
echo "AhD6areifeegh4Ua" | sudo passwd --stdin afornaguera
echo "AhD6areifeegh4Ua" | sudo passwd --stdin jdelosmozos
echo "AhD6areifeegh4Ua" | sudo passwd --stdin nasensi
echo "AhD6areifeegh4Ua" | sudo passwd --stdin nhumet

# Añadir los usuarios al grupo wheel para poder hacer sudo
sudo usermod -aG wheel acarrillo
sudo usermod -aG wheel amisis
sudo usermod -aG wheel omontero
sudo usermod -aG wheel gpuig
sudo usermod -aG wheel pgallego
sudo usermod -aG wheel jorovengua
sudo usermod -aG wheel afornaguera
sudo usermod -aG wheel jdelosmozos
sudo usermod -aG wheel nasensi
sudo usermod -aG wheel nhumet

# Instalar paquetes necesarios
sudo dnf install -y git gcc wget nodejs libxslt-devel bzip2-devel openldap-devel libjpeg-devel freetype-devel postgresql-libs postgresql-devel gcc-c++ epel-release
sudo dnf install -y python39 python39-devel

# Instalar conversor html a pdf
sudo mkdir -p /opt/odoo/
sudo wget -P /opt/odoo https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox-0.12.6.1-2.almalinux8.x86_64.rpm
sudo dnf localinstall -y /opt/odoo/wkhtmltox-0.12.6.1-2.almalinux8.x86_64.rpm

# Instalar PostgreSQL
sudo dnf install -y postgresql postgresql-server postgresql-contrib

# Encender el PostgreSQL
sudo /usr/bin/postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Crear usuario odoo en PostgreSQL
sudo su - postgres -c "createuser -s odoo"

# Crear usuario odoo y preparar el entorno
sudo useradd -m -U -r -d /opt/odoo -s /bin/bash odoo
sudo chown -R odoo /opt/odoo
sudo chgrp -R odoo /opt/odoo
sudo su - odoo -c "git clone https://www.github.com/odoo/odoo --depth 1 --branch 15.0 /opt/odoo/odoo15"
sudo su - odoo -c "python3.9 -m venv /opt/odoo/odoo15-venv"
sudo su - odoo -c "source /opt/odoo/odoo15-venv/bin/activate && pip install --upgrade pip && pip install -r /opt/odoo/odoo15/requirements.txt && pip install psycopg2-binary && deactivate"
sudo su - odoo -c "mkdir /opt/odoo/odoo15-custom-addons"
sudo su - odoo -c "exit"

# Crear directorio de registro de Odoo y Odoo-desa
sudo mkdir /var/log/odoo15

# Creación de los registros
sudo touch /var/log/odoo15/odoo-desa.log
sudo touch /var/log/odoo15/odoo.log

# Dar permisos al usuario de odoo a los logs
sudo chown -R odoo:odoo /var/log/odoo15/

# Crear archivo de configuración de instancia de desarrollo
sudo sh -c 'cat <<EOF > /etc/odoo-desa.conf
[options]
; This is the password that allows database operations:
admin_passwd = Iedoo8oo ohPii4ai
db_host = False
db_port = False
db_user = odoo
db_password = False
xmlrpc_port = 8073
longpolling_port = 8074
logfile = /var/log/odoo15/odoo-desa.log
logrotate = True
addons_path = /opt/odoo/odoo15/addons,/opt/odoo/odoo15-custom-addons
workers = 2
proxy_mode = True
EOF'

# Crear archivo de servicio systemd de instancia de desarrollo
sudo sh -c 'cat <<EOF > /etc/systemd/system/odoo15-desa.service
[Unit]
Description=Odoo15
StartLimitIntervalSec=300
StartLimitBurst=5
[Service]
Type=simple
SyslogIdentifier=odoo15-desa
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo15-venv/bin/python3.9 /opt/odoo/odoo15/odoo-bin -c /etc/odoo-desa.conf
StandardOutput=journal+console
Restart=on-failure
RestartSec=1s
[Install]
WantedBy=multi-user.target
EOF'

# Crear archivo de configuración de Odoo
sudo sh -c 'cat <<EOF > /etc/odoo.conf
[options]
; This is the password that allows database operations:
admin_passwd = Iedoo8oo ohPii4ai
db_host = False
db_port = False
db_user = odoo
db_password = False
xmlrpc_port = 8069
longpolling_port = 8072
logfile = /var/log/odoo15/odoo.log
logrotate = True
addons_path = /opt/odoo/odoo15/addons,/opt/odoo/odoo15-custom-addons
workers = 2
proxy_mode = True
EOF'

# Crear archivo de servicio systemd de Odoo
sudo sh -c 'cat <<EOF > /etc/systemd/system/odoo15.service
[Unit]
Description=Odoo15
StartLimitIntervalSec=300
StartLimitBurst=5
[Service]
Type=simple
SyslogIdentifier=odoo15
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo15-venv/bin/python3.9 /opt/odoo/odoo15/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console
Restart=on-failure
RestartSec=1s
[Install]
WantedBy=multi-user.target
EOF'

# Recargar servicios systemd otra vez
sudo systemctl daemon-reload

# Iniciar y habilitar el servicio Odoo15
sudo systemctl start odoo15
sudo systemctl enable odoo15

# Instalar NGINX y Certbot
sudo dnf install -y certbot nginx

# Creación de las carpetas sites-available y sites-enabled
sudo mkdir -p /etc/nginx/sites-available && sudo mkdir -p /etc/nginx/sites-enabled

# Crear el archivo dhparam.pem
sudo mkdir -p /etc/cert/certs
sudo sh -c 'cat <<EOF > /etc/cert/certs/dhparam.pem
-----BEGIN DH PARAMETERS-----
MIICCAKCAgEA3eINXN1xzhfnc7ku6Vuim65H0K+kjZD9yiKVLTBw41EYJVfRupOX
ze05bzJFQlLipBiI9OAOWuiwLLkFeGxu3fFkOVfaviR5VBpPz6sQYwNL152Fs37y
j74Y8orq01sgn+BB++S0CIQCh+AQWzSjyEnGuME93wH2NBMl52Ht9ZWmFSn6XvQM
Tvx5vpBNk/4+i5NPZ6Ptc6jH1lofXh/0F1Yvg0yUyhYJzzwJUNrRju5V0y4qS3Y1
HiU267HEd7T1zuc20Yl+/Rs8lULe6+kS77Y3+5u1hozen4WcM2rIxGEBCBCDjNf9
km5wP1HHhnq/KZtlv0u68wEW73AO5zWzLRI2KaclS0X2c4zMkvM3q1BlE1ZSctq6
lR08sR3zCENrpLqtRL4+0HWNxUEBAPjq/4jyacmbFsQ/59D9dCiJt/hLehG3O8P1
OYRWqCMuOQT4T78wQQcTZHxguxdaUdxmgfNBP0SXfjeebApgpg8YhtgD1biGYFqc
lCHvoHALCBwvQWgu5lCd+RuBqPXRTC27fy9xpo1js9+KzJpxIluqodDBGlX88VYJ
ZkGswo0RIqst5AbE8w9Dq3lEmPH3Y68ViFzvbFtePFx9NdxvTjLhMNzvZvQGgWJI
eeXdqk+M3lfk6Rmy+LrqUiru/fPbPNPLyAFBByTmYf8OMQA/cOiKrAMCAQI=
-----END DH PARAMETERS-----
EOF'

# Crear enlace simbolico al fichero de Odoo.
# sudo ln -s /etc/nginx/sites-available/odoo.conf /etc/nginx/sites-enabled/odoo.conf

# Iniciar el servicio de Nginx
# sudo systemctl enable nginx
# sudo systemctl start nginx

# Instalar Firewalld
sudo dnf install -y firewalld

# Encender el servicio de Firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Añadir los puertos al Firewalld (Si instalas NGINX y lo configuras manualmente)
sudo firewall-cmd --add-port=80/tcp && sudo firewall-cmd --add-port=443/tcp && sudo firewall-cmd --add-port=8888/tcp

# Hacer un port forwarding para conectarse al odoo(Solo si el NGINX no está configurado porque falta SSL)

# sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8069

# Guardar la configuración del firewalld
sudo firewall-cmd --runtime-to-permanent
