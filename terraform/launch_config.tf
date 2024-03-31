#Create Launch config

resource "aws_launch_configuration" "wp-launch-config" {
  name                        = "wp-launch-config"
  image_id                    = var.ami_id
  instance_type               = "t3.small"
  key_name                    = var.keyname
  security_groups             = [aws_security_group.private_ssh_sg.id]
  associate_public_ip_address = false
  user_data                   = filebase64("${path.module}/user_data.sh")
  root_block_device {
    volume_size = 20
    volume_type = "gp2"
    encrypted   = true
  }
}