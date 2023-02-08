#!/bin/bash

#connect wifi
sudo yum install dkms git -y
sudo dnf install kernel-devel-$(uname -r) -y

git clone "https://github.com/RinCat/RTL88x2BU-Linux-Driver.git" /usr/src/rtl88x2bu-git
sed -i 's/PACKAGE_VERSION="@PKGVER@"/PACKAGE_VERSION="git"/g' /usr/src/rtl88x2bu-git/dkms.conf
dkms add -m rtl88x2bu -v git
dkms autoinstall

sudo nmcli device wifi connect TP-Link_1117_5G password 11203247

#install cockpit
sudo dnf install cockpit -y
sudo systemctl enable --now cockpit.socket
sudo firewall-cmd --add-service=cockpit
sudo firewall-cmd --add-service=cockpit --permanent

#install docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo systemctl start docker

sudo dnf install docker-compose -y

sudo systemctl enable docker.service
sudo systemctl enable containerd.service

#create users for docker
echo "umask 077" >> ~/.bashrc

sudo groupadd docker_files -g 1002
sudo groupadd docker_movies -g 1003
sudo groupadd docker_x -g 1004
sudo groupadd docker_music -g 1005
sudo groupadd docker_games -g 1006
sudo groupadd docker_courses -g 1007

sudo adduser --system  docker_files --uid 1102 -g 1002
sudo usermod -s /sbin/nologin docker_files

sudo adduser --system  docker_movies --uid 1103 -g 1003
sudo usermod -s /sbin/nologin docker_movies

sudo adduser --system  docker_x --uid 1104 -g 1004
sudo usermod -s /sbin/nologin docker_x

sudo adduser --system  docker_music --uid 1105 -g 1005
sudo usermod -s /sbin/nologin docker_music

sudo adduser --system  docker_games --uid 1106 -g 1006
sudo usermod -s /sbin/nologin docker_games

sudo adduser --system  docker_courses --uid 1107 -g 1007
sudo usermod -s /sbin/nologin docker_courses



#install backup tools
sudo dnf install borgbackup -y
sudo dnf install borgmatic -y
sudo generate-borgmatic-config

mkdir /mnt/Backups
echo "

location:
    # List of source directories to backup.
    source_directories:
#        - /home
        - /etc
        - /docker_data
#        - /mnt/Documents

    # Paths of local or remote repositories to backup to.
    repositories:
        - /mnt/Backups/

retention:
    # Retention policy for how many backups to keep.
    keep_daily: 7
    keep_weekly: 4
    keep_monthly: 6

consistency:
    # List of checks to run to validate your backups.
    checks:
        - name: repository
        - name: archives
          frequency: 2 weeks

hooks:
#    # Custom preparation scripts to run.
    before_backup:
        - /docker_sh/stop_all.sh
    after_backup:
        - /docker_sh/start_all.sh
        
" > /etc/borgmatic/config.yaml

borg init --encryption=none /mnt/Backups

mkdir /docker_sh

echo "
docker start \$(docker ps -a -q)
" > /docker_sh/start_all.sh

echo "
docker stop \$(docker ps -a -q)" > /docker_sh/stop_all.sh

chmod +x /docker_sh/stop_all.sh
chmod +x /docker_sh/start_all.sh

#parameters for hdd
echo "sudo /sbin/hdparm -B 255 /dev/sdb > /dev/null" >> ~/.bashrc file
echo "sudo /sbin/hdparm -B 255 /dev/sdc > /dev/null" >> ~/.bashrc file
echo "sudo /sbin/hdparm -B 255 /dev/sde > /dev/null" >> ~/.bashrc file

sudo yum install smartmontools -y
sudo yum install hdparm -y


cd dockers/
for f in `ls`
do
 echo "Processing $f"
 docker-compose up -d -f $f
done
