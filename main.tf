provider "aws" {
  region     = "eu-west-3"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Ppro_IGW"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

}

resource "aws_subnet" "ec2_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "lb_subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "eu-west-3c"
  cidr_block        = "10.0.4.0/24"
}

resource "aws_subnet" "rds_subnet_1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "eu-west-3a"
  cidr_block        = "10.0.2.0/28"
}

resource "aws_subnet" "rds_subnet_2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "eu-west-3c"
  cidr_block        = "10.0.3.0/28"
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "main"
  subnet_ids = [aws_subnet.rds_subnet_1.id, aws_subnet.rds_subnet_2.id]

  tags = {
    Name = "DB subnet group"
  }
}

variable "environment" {
  type = string
}

resource "aws_instance" "workers" {
  count         = 4
  ami           = "ami-0326f9264af7e51e2"
  instance_type = var.environment == "Prod" ? "t3.large" : "t3.medium"
  subnet_id     = aws_subnet.ec2_subnet.id

  tags = {
    Name = "Worker ${count.index + 1}"
  }
}

resource "aws_instance" "control_plane" {
  count         = 2
  ami           = "ami-0326f9264af7e51e2"
  instance_type = var.environment == "Prod" ? "t3.large" : "t3.medium"
  subnet_id     = aws_subnet.ec2_subnet.id

    tags = {
    Name = "Master ${count.index + 1}"
  }
}

resource "aws_db_instance" "rds_db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = var.environment == "Prod" ? "db.t3.large" : "db.t3.small"
  db_name              = "k8_db"
  username             = "admin"
  password             = "vTestadminv"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}

resource "aws_s3_bucket" "backup" {
  bucket = "rds-backup-bucket-pjpro"
}

resource "aws_security_group" "vm_sg" {
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "Allow_http" {
  security_group_id = aws_security_group.vm_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "Allow_https" {
  security_group_id = aws_security_group.vm_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}


resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "Allow_sql" {
  security_group_id = aws_security_group.rds_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 3306
  ip_protocol = "tcp"
  to_port     = 3306
}

resource "aws_lb" "front_end" {
  name               = "frontend-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vm_sg.id]
  subnets            = [aws_subnet.ec2_subnet.id, aws_subnet.lb_subnet.id]

#   access_logs {
#     bucket  = aws_s3_bucket.backup.id
#     prefix  = "Application_lb"
#     enabled = true
#   }
}

# resource "aws_route53_record" "lb_dns" {
#   zone_id = "Z3P5QSUBK4POTI"
#   name    = "api.aratrpro.com"
#   type    = "A"
#   alias {
#     name                   = aws_lb.front_end.dns_name
#     zone_id                = aws_lb.front_end.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_lb_target_group" "lb_target_group" {
#   name     = "tf-example-lb-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id
# }

# resource "aws_lb_target_group_attachment" "test" {
#   target_group_arn = aws_lb_target_group.lb_target_group.arn
#   target_id        = aws_instance.test.id
#   port             = 80
# }

output "workers_instance_id" {

  value = aws_instance.workers[*].id
  description = "Instance ID workers"

}

output "Controlplanes_instance_id" {

  value = aws_instance.control_plane[*].id
  description = "Instance ID controlplane"

}