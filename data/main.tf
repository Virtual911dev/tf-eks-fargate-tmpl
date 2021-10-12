provider "local" {
  version = "~> 1.4"
}

resource "aws_db_subnet_group" "lynxdata" {
  name       = "lynxdata"
  subnet_ids = var.private_subnets.*.id
  tags = {
    Name = "lynxdata"
  }
}


resource "aws_security_group" "rds" {
  name   = "lynxdata_rds"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["83.103.155.177/32"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lynxdata_rds"
  }
}

#RDS PsotgreSql instance
resource "aws_db_instance" "lynxdata" {
  identifier             = "lynx-data"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "11"
  username               = var.data_username
  password               = var.data_password
  db_subnet_group_name   = aws_db_subnet_group.lynxdata.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
}

resource "aws_db_parameter_group" "lynxdata" {
  name   = "lynxdata"
  family = "postgres11"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}
