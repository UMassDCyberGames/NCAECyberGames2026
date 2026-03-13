
### From webserver

- Add a firewall rule to explicitly allow SSH traffic from backup server

``` bash
# Explicity allow SSH traffic from backup server
sudo ufw allow from 192.168.9.15 to any port 22 proto tcp
```

- Create a dedicated backupuser

``` bash
sudo useradd -m -s /bin/bash backupuser
```

- Create the SSH directories on the webserver:
``` bash
sudo mkdir -p /home/backupuser/.ssh
sudo chown backupuser:backupuser /home/backupuser/.ssh
sudo chmod 700 /home/backupuser/.ssh
```

### From backup server

- Only allow internal backup traffic.

``` bash
ufw allow from 192.168.9.0/24 to any port 22
ufw deny from 172.18.0.0/16
```

- Generate key pair on backup server

``` bash
ssh-keygen -t rsa -b 4096
```

- This creates

``` bash
~/.ssh/id_rsa        (private key)
~/.ssh/id_rsa.pub    (public key)
```

- Private keys stay only on the backup server
- Copy public keys to webserver

``` bash
ssh-copy-id backupuser@192.168.9.5
```


- This adds the public keys to:

``` bash
~/backupuser/.ssh/authorized_keys
```

- Test SSH access via private key from backup server and jump host. Do not close your existing SSH sessions until you confirm the new one works.

``` bash
ssh -i id_rsa backupuser@<webserver_IP>
```

- Secure the SSH config

``` bash
sudo nano /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
AllowUsers backupuser jumphost_user
```

- Restart SSH

``` bash
sudo systemctl restart ssh
```

- Test SSH access again from new terminal on backup server and jump host

``` bash
ssh -i id_rsa backupuser@<webserver_IP>
ssh -i id_rsa jumphost_user@<webserver_IP>
```