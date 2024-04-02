#Create Launch template

resource "aws_launch_template" "wp-launch-template" {
  name          = "wp-launch-template"
  image_id      = var.ami_id
  instance_type = "t3.small"
  key_name      = var.keyname
  

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.private_ssh_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name       = "wp-launch-template"
      CostCenter = "C092000024"
      project    = "PB UNICESUMAR"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name       = "wp-launch-template"
      CostCenter = "C092000024"
      project    = "PB UNICESUMAR"
    }
  }
user_data = base64encode(<<EOF
#!/bin/bash

yum update -y
yum install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

sudo yum install -y amazon-efs-utils
mkdir -p /mnt/nfs/wordpress
echo "${aws_efs_file_system.efs.dns_name}:/ /mnt/nfs/wordpress nfs defaults,_netdev 0 0" >> /etc/fstab
mount -a

curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

cat <<EOL > /home/ec2-user/docker-compose.yml
version: '3.8'
services:
  wp-web:
    image: wordpress:latest
    restart: always
    ports:
      - 80:80
    environment:
      TZ: America/Sao_Paulo
      WORDPRESS_DB_HOST: ${aws_db_instance.rds_instance.endpoint}
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: admin123
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /mnt/nfs/wordpress:/var/www/html
EOL

docker-compose -f /home/ec2-user/docker-compose.yml up -d
EOF
)

 
}


