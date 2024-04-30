terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.47.0"
    }
  



  backend "http" {
    address        = "https://gitlab.com/ara1504621/terraform-test/terraform/state/ppro_state"
    lock_address   = "https://gitlab.com/ara1504621/terraform-test/terraform/state/ppro_state/lock"
    unlock_address = "https://gitlab.com/ara1504621/terraform-test/terraform/state/ppro_state/lock"
    username       = "gitlab-ci-token"
    password       = var.GITLAB_TOKEN
  }
}

provider "aws" {
  region = "eu-west-3" 
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main_vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_IGW"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}


resource "aws_subnet" "sub_1_ec2_lb" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
  tags = {
    Name = "main_subnet"
  }
}

resource "aws_subnet" "sub_2_ec2_lb" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-3c"
  tags = {
    Name = "lb_subnet"
  }
}

resource "aws_subnet" "RDS_sub1" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.3.0/28"
  availability_zone = "eu-west-3b"
  tags = {
    Name = "RDS_sub1"
  }
}

resource "aws_subnet" "RDS_sub2" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.4.0/28"
  availability_zone = "eu-west-3c"
  tags = {
    Name = "RDS_sub2"
  }
}
resource "aws_db_subnet_group" "default" {
  name       = "main_db_grp"
  subnet_ids = [aws_subnet.RDS_sub1.id, aws_subnet.RDS_sub2.id]

  tags = {
    Name = "DB subnet group"
  }
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id 
}


resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "Allow inbound traffic from EC2 security group"
  vpc_id      = aws_vpc.main_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_mysql" {
  security_group_id = aws_security_group.rds_security_group.id
  referenced_security_group_id = aws_security_group.allow_ssh_http.id
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_out" {
  security_group_id = aws_security_group.rds_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  db_name              = "db_app"
  identifier           = "devopsdb-app"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.environment == "Prod" ? "db.t3.large" : "db.t3.micro"
  username             = "admin"
  password             = "vAdmintestv"
  db_subnet_group_name = aws_db_subnet_group.default.name
  multi_az             = false
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  skip_final_snapshot  = var.environment == "Prod" ? false : true
  final_snapshot_identifier = var.environment == "Prod" ? "Db_snapshot" : null
}

resource "aws_instance" "control_plane" {
  count         = var.control_plane_instance_number
  ami           = "ami-0326f9264af7e51e2"
  instance_type = var.environment == "Prod" ? "t3.large" : "t2.micro"
  key_name      = "Pjpro_key"
  subnet_id                   = aws_subnet.sub_1_ec2_lb.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  associate_public_ip_address = false

  #user_data = file("${path.module}/setup.sh")

  tags = {
    Name = "Controlplane ${count.index + 1}"
  }
}

resource "aws_instance" "workers" {
  count = var.worker_instance_number
  ami           = "ami-0326f9264af7e51e2"
  instance_type = var.environment == "Prod" ? "t3.large" : "t2.micro"
  key_name      = "Pjpro_key"
  subnet_id                   = aws_subnet.sub_1_ec2_lb.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  associate_public_ip_address = false

  #user_data = file("${path.module}/setup.sh")

  tags = {
    Name = "K8s Worker ${count.index + 1}"
  }
}

# Outputs for RDS instance
output "database_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.default.endpoint
}

output "database_username" {
  description = "The username of the database"
  value       = aws_db_instance.default.username
}

output "database_password" {
  description = "The password of the database"
  value       = aws_db_instance.default.password
  sensitive = true
}

output "database_name" {
  description = "The name of the database"
  value       = aws_db_instance.default.db_name
}

output "ctrl_instance_name" {
  value = aws_instance.workers[*].tags
}

output "wrks_instance_name" {
  value = aws_instance.control_plane[*].tags
}