# Create bastion host
resource "aws_instance" "bastion" {
  count                       = 1
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  security_groups             = [aws_security_group.bastion_sg.id]
  subnet_id                   = aws_subnet.subnet-public-a.id
  key_name                    = var.keyname
  associate_public_ip_address = true
  tags = {
    Name       = "bastion_host ${count.index}"
    Project    = "PB UNICESUMAR"
    CostCenter = "C092000024"
  }

  volume_tags = {
    Name       = "bastion_host ${count.index}"
    Project    = "PB UNICESUMAR"
    CostCenter = "C092000024"
  }
}