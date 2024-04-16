# Create EFS

resource "aws_efs_file_system" "efs" {
  creation_token = "efs-project-docker"
  encrypted      = true

  tags = {
    Name = "efs-project-docker ${var.environment}"
  }
}

resource "aws_efs_mount_target" "efs-mt-a" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.subnet-private-a.id
  security_groups = [aws_security_group.private_ssh_sg.id]

}

resource "aws_efs_mount_target" "efs-mt-b" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.subnet-private-b.id
  security_groups = [aws_security_group.private_ssh_sg.id]

}