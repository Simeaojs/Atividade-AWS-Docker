#rds subnet

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group ${var.environment}"
  subnet_ids = [aws_subnet.subnet-private-a.id, aws_subnet.subnet-private-b.id]

}
#RDS INSTANCE

resource "aws_db_instance" "rds_instance" {
  engine                    = "mysql"
  engine_version            = "8.0.35"
  skip_final_snapshot       = true
  final_snapshot_identifier = "my-final-snapshot"
  allocated_storage         = 20
  instance_class            = "db.t3.micro"
  identifier                = "my-rds-instance"
  db_name                   = "wordpress"
  username                  = "admin"
  password                  = "admin123"
  db_subnet_group_name      = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]

  tags = {
    Name = "rds-project-docker ${var.environment}"
  }

}
# RDS security group

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-project-docker ${var.environment}"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.110.0.0/16"]
  }

  tags = {
    Name = "rds-sg-project-docker ${var.environment}"
  }
}