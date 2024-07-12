terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.47.0"
    }
  }



  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/57372801/terraform/state/$TF_STATE_NAME"
    lock_address   = "https://gitlab.com/api/v4/projects/57372801/terraform/state/$TF_STATE_NAME/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/57372801/terraform/state/$TF_STATE_NAME/lock"
    username       = "Nevii"
    password       = "$CI_JOB_TOKEN"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
    }
  
}
provider "aws" {
  region = "eu-west-3"
  
}

data "aws_vpc" "target_peering_vpc" {
  id = "vpc-0f4d614772ca8d3f0"
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

resource "aws_security_group" "kubernetes_controlplane" {
  name        = "ctlplane_sg"
  description = "Allow SSH and necessary ports for k8s cluster - ctlplane"
  vpc_id      = aws_vpc.main_vpc.id 
}


resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ctlplane" {
  security_group_id = aws_security_group.kubernetes_controlplane.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_kube_api" {
  security_group_id = aws_security_group.kubernetes_controlplane.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

resource "aws_vpc_security_group_ingress_rule" "allow_etcd_server_client_api" {
  security_group_id = aws_security_group.kubernetes_controlplane.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 2379
  ip_protocol       = "tcp"
  to_port           = 2380
}

resource "aws_vpc_security_group_ingress_rule" "kubelet_scheduler_kubelet_k_controller" {
  security_group_id = aws_security_group.kubernetes_controlplane.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 10250
  ip_protocol       = "tcp"
  to_port           = 10259
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.kubernetes_controlplane.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_security_group" "kubernetes_workers" {
  name        = "workers_sg"
  description = "Allow SSH and necessary ports for k8s cluster - workers"
  vpc_id      = aws_vpc.main_vpc.id 
}

resource "aws_vpc_security_group_ingress_rule" "kubelet_api" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 10250
  ip_protocol       = "tcp"
  to_port           = 10250
}


resource "aws_vpc_security_group_ingress_rule" "nodeport_svc" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_controlplane.id
  from_port         = 30000
  ip_protocol       = "tcp"
  to_port           = 32767
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_workers" {
  security_group_id = aws_security_group.kubernetes_workers.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_out" {
  security_group_id = aws_security_group.kubernetes_workers.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# resource "aws_security_group" "rds_security_group" {
#   name        = "rds_security_group"
#   description = "Allow inbound traffic from EC2 security group"
#   vpc_id      = aws_vpc.main_vpc.id
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_mysql" {
#   security_group_id = aws_security_group.rds_security_group.id
#   referenced_security_group_id = aws_security_group.kubernetes_controlplane.id
#   from_port         = 3306
#   ip_protocol       = "tcp"
#   to_port           = 3306
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_out" {
#   security_group_id = aws_security_group.rds_security_group.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

# resource "aws_db_instance" "default" {
#   allocated_storage    = 20
#   db_name              = "db_app"
#   identifier           = "devopsdb-app"
#   engine               = "mysql"
#   engine_version       = "8.0"
#   instance_class       = var.environment == "Prod" ? "db.t3.large" : "db.t3.micro"
#   username             = "admin"
#   password             = "vAdmintestv"
#   db_subnet_group_name = aws_db_subnet_group.default.name
#   multi_az             = false
#   vpc_security_group_ids = [aws_security_group.rds_security_group.id]
#   skip_final_snapshot  = var.environment == "Prod" ? false : true
#   final_snapshot_identifier = var.environment == "Prod" ? "Db_snapshot" : null
# }

resource "aws_instance" "control_plane" {
  count         = var.control_plane_instance_number
  ami           = "ami-0326f9264af7e51e2"
  instance_type = var.environment == "Prod" ? "t3.large" : "t2.medium"
  key_name      = "Pjpro_key"
  subnet_id                   = aws_subnet.sub_1_ec2_lb.id
  vpc_security_group_ids      = [aws_security_group.kubernetes_workers.id]
  associate_public_ip_address = true

  #user_data = file("${path.module}/setup.sh")

  tags = {
    Name = "Controlplane ${count.index + 1}"
    role = "Master"
    environment = var.environment
  }
}

resource "aws_instance" "workers" {
  count = var.worker_instance_number
  ami           = "ami-0326f9264af7e51e2"
  instance_type = var.environment == "Prod" ? "t3.large" : "t2.micro"
  key_name      = "Pjpro_key"
  subnet_id                   = aws_subnet.sub_1_ec2_lb.id
  vpc_security_group_ids      = [aws_security_group.kubernetes_controlplane.id]
  associate_public_ip_address = true

  #user_data = file("${path.module}/setup.sh")

  tags = {
    Name = "K8s Worker ${count.index + 1}"
    role = "Worker"
    environment = var.environment
  }
}

resource "aws_vpc_peering_connection" "vpc_gitlab_runner" {
  peer_vpc_id   = data.aws_vpc.target_peering_vpc.id
  vpc_id        = aws_vpc.main_vpc.id

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_gitlab_runner.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

# Outputs for RDS instance
# output "database_endpoint" {
#   description = "The endpoint of the database"
#   value       = aws_db_instance.default.endpoint
# }

# output "database_username" {
#   description = "The username of the database"
#   value       = aws_db_instance.default.username
# }

# output "database_password" {
#   description = "The password of the database"
#   value       = aws_db_instance.default.password
#   sensitive = true
# }

# output "database_name" {
#   description = "The name of the database"
#   value       = aws_db_instance.default.db_name
# }

output "ctrl_instance_name" {
  value = aws_instance.workers[*].tags
}

output "wrks_instance_name" {
  value = aws_instance.control_plane[*].tags
}

output "private_ip" {
  value = aws_instance.control_plane[*].private_ip
}

# Create a route for the second VPC's CIDR block in the first VPC's route table
resource "aws_route" "main_vpc_route_to_k8s" {
  route_table_id            = "rtb-0cb9914b16f6618ed"
  destination_cidr_block    = "10.0.0.0/16" # Replace with the other VPC's CIDR block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_gitlab_runner.id
}



# Create a route for the first VPC's CIDR block in the second VPC's route table
resource "aws_route" "vpc2_route" {
  route_table_id            = aws_vpc.main_vpc.main_route_table_id
  destination_cidr_block    = "172.31.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_gitlab_runner.id
}

# Associate the route tables with the subnets in the VPCs
# Replace the subnet IDs with the actual IDs of the subnets in the VPCs

data "aws_subnet" "gitlab_runner_sub" {
  id = "subnet-0eea324505858e7f7"
}

resource "aws_iam_role" "node" {
  name = "eks-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_eks_cluster" "main" {
  name     = "Demo-eks"
  role_arn = aws_iam_role.node.arn

  vpc_config {
    subnet_ids = [aws_subnet.sub_1_ec2_lb.id, aws_subnet.sub_2_ec2_lb.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.node-AmazonEKSServicePolicy,
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name  = "eks-nodes"
  node_role_arn    = aws_iam_role.node.arn
  subnet_ids      = [aws_subnet.sub_1_ec2_lb.id, aws_subnet.sub_2_ec2_lb.id]

  scaling_config {
    desired_size = 5
    max_size     = 10
    min_size     = 5
  }
}

output "node_group_id" {
  value = aws_eks_node_group.main.node_group_id
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "node_group_name" {
  value = aws_eks_node_group.main.node_group_name
}