### Configure Network Adapter

``` bash
cd /etc/sysconfig/network-scripts/

# Each interface has config file
cat ifcfg-eth0
cat ifcfg-ens33
cat ifcfg-enp0s3

# Determine interface name
ip addr

# sudo nano /etc/sysconfig/network-scripts/ifcfg-ens33
# static adapter
TYPE=Ethernet  
BOOTPROTO=none  # static IP
# NAME=ens33  
# DEVICE=ens33  # device identifier
ONBOOT=yes  

IPADDR=192.168.9.15
PREFIX=24  
GATEWAY=192.168.9.1

nmcli connection reload
nmcli connection up ens33

# Check config
nmcli connection show

# Check logs
journalctl -U NetworkManager

```

### Firewall the backup server

``` bash
ufw default deny incoming  
ufw default allow outgoing  
  
# allow SSH only from backup internal subnet  
ufw allow from 192.168.9.0/24 to any port 22  
  
# allow SMB server exception  
ufw allow from 172.18.14.9 to any port 22  
  
# block all external LAN  
ufw deny from 172.18.0.0/16
```

### Install rsync openssh-client

``` bash
sudo apt update
sudo apt install rsync openssh-client -y

sudo mkdir -p /backups
```

### Generate SSH keys

``` bash
ssh-keygen -t rsa -b 4096

ssh-copy-id backupuser@192.168.9.5     # web
ssh-copy-id backupuser@192.168.9.7     # db
ssh-copy-id backupuser@192.168.9.12    # dns
ssh-copy-id backupuser@172.18.14.9     # smb/shell
```


### Test Passwordless Login from the Backup Server

- From the backup server should be able to login to each VM without password

``` bash
ssh backupuser@192.168.9.5
ssh backupuser@192.168.9.7
ssh backupuser@192.168.9.12 
ssh backupuser@172.18.14.9
```

### Disable Passwordless Login

- Edit the backup server's SSH server config
``` bash
# Add or modify these lines
sudo nano /etc/ssh/sshd_config
PasswordAuthentication no
PermitRootLogin no

# Additional hardening recommended
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
AllowUsers backupuser admin

sudo systemctl restart ssh
# or
sudo systemctl restart sshd
```

### Create snapshot directories

``` bash
mkdir -p /backups/web
mkdir -p /backups/db
mkdir -p /backups/dns
mkdir -p /backups/shell
mkdir -p /backups/router
```

### Pull Critical Configs with rsync

``` bash
# Webserver
rsync -avz backupuser@192.168.t.5:/etc/apache2 /backups/web/
rsync -avz backupuser@192.168.t.5:/var/www /backups/web/
```

``` bash
# dbserver
rsync -avz backupuser@192.168.t.7:/etc/mysql /backups/db/

# Optional DB dump
ssh backupuser@192.168.t.7 "mysqldump --all-databases" > /backups/db/db.sql
```

``` bash
# DNS server
rsync -avz backupuser@192.168.t.12:/etc/bind /backups/dns/
```

``` bash
# SMB/shell server
rsync -avz backupuser@172.18.14.9:/etc/samba /backups/shell/
rsync -avz backupuser@172.18.14.9:/etc/ssh /backups/shell/
```

``` bash
# MikroTik router
ssh admin@192.168.9.1 "/export show-sensitive" > /backups/router/router_config.txt
```

### Timestamp Each Snapshot

``` bash
# Before each run
DATE=$(date +%F_%H-%M)

mkdir -p /backups/snapshots/$DATE

# then copy backups into it
cp -r /backups/web /backups/snapshots/$DATE/
cp -r /backups/db /backups/snapshots/$DATE/
cp -r /backups/dns /backups/snapshots/$DATE/
cp -r /backups/shell /backups/snapshots/$DATE/
cp -r /backups/router /backups/snapshots/$DATE/
```

### Automate with Crontab

``` bash
crontab -e

*/5 * * * * /opt/backup.sh
```

### Contents of backup.sh

``` bash
#!/bin/bash
DATE=$(date +%F_%H-%M)
BASE="/backups/snapshots/$DATE"

mkdir -p $BASE

rsync -a backupuser@192.168.9.5:/etc/apache2 $BASE/web/
rsync -a backupuser@192.168.9.5:/var/www $BASE/web/

rsync -a backupuser@192.168.9.7:/etc/postgres $BASE/db/

rsync -a backupuser@192.168.9.12:/etc/bind $BASE/dns/

rsync -a backupuser@172.18.14.9:/etc/samba $BASE/shell/
rsync -a backupuser@172.18.14.9:/etc/ssh $BASE/shell/

ssh admin@192.168.9.1 "/export show-sensitive" > $BASE/router.txt
```