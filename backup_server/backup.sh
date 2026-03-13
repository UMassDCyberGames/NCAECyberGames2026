#!/bin/bash

DATE=$(date +%F_%H-%M)
BASE="/backups/snapshots/$DATE"

mkdir -p $BASE

rsync -a backupuser@192.168.9.5:/etc/apache2 $BASE/web/
rsync -a backupuser@192.168.9.5:/var/www $BASE/web/

rsync -a backupuser@192.168.9.7:/etc/mysql $BASE/db/

rsync -a backupuser@192.168.9.12:/etc/bind $BASE/dns/

rsync -a backupuser@172.18.14.9:/etc/samba $BASE/shell/
rsync -a backupuser@172.18.14.9:/etc/ssh $BASE/shell/

ssh admin@192.168.9.1 "/export show-sensitive" > $BASE/router.txt