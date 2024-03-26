
#!/bin/bash

# Instalação e configuração do Docker
yum update -y
yum install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Instalação do docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Montagem do EFS
sudo yum install -y amazon-efs-utils
mkdir -p /mnt/nfs/wordpress
echo "fs-0484f8de42c4fe635.efs.us-east-1.amazonaws.com:/ /mnt/nfs/wordpress nfs defaults,_netdev 0 0" >> /etc/fstab
mount -a

# Executando o docker-compose do repositório
yum install git -y
git clone https://github.com/Simeaojs/wordpress.git /home/ec2-user/wordpress
cd /home/ec2-user/wordpress
docker-compose up -d