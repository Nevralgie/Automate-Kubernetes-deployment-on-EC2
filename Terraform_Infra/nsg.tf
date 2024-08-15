resource "aws_security_group" "kubernetes_controlplane" {
  name        = "ctlplane_sg"
  description = "Allow SSH and necessary ports for k8s cluster - ctlplane"
  vpc_id      = aws_vpc.main_vpc.id 
}


resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ctlplane_ec2_connect" {
  security_group_id = aws_security_group.kubernetes_controlplane.id
  cidr_ipv4         = "35.180.112.80/29"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ctlplane_from_gitlab_runner" {
  security_group_id = aws_security_group.kubernetes_controlplane.id
  cidr_ipv4         = "172.31.32.99/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "core_dns_from_workers" {
  security_group_id = aws_security_group.kubernetes_controlplane.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 53
  ip_protocol       = "tcp"
  to_port           = 53
}

resource "aws_vpc_security_group_ingress_rule" "calico_networking_bgp_ctl" {
  security_group_id = aws_security_group.kubernetes_controlplane.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 179
  ip_protocol       = "tcp"
  to_port           = 179
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

resource "aws_vpc_security_group_ingress_rule" "core_dns_from_ctlplane" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_controlplane.id
  from_port         = 53
  ip_protocol       = "tcp"
  to_port           = 53
}

resource "aws_vpc_security_group_ingress_rule" "calico_networking_bgp_wks" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 179
  ip_protocol       = "tcp"
  to_port           = 179
}

resource "aws_vpc_security_group_ingress_rule" "calico_networking_bgp_ctltowks" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_controlplane.id
  from_port         = 179
  ip_protocol       = "tcp"
  to_port           = 179
}


resource "aws_vpc_security_group_ingress_rule" "kubelet_api" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 10250
  ip_protocol       = "tcp"
  to_port           = 10259
}

resource "aws_vpc_security_group_ingress_rule" "kubelet_api_2" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_controlplane.id
  from_port         = 10250
  ip_protocol       = "tcp"
  to_port           = 10259
}

resource "aws_vpc_security_group_ingress_rule" "local_ai" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "mysql_containerized_db" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_vpc_security_group_ingress_rule" "k8sgpt" {
  security_group_id = aws_security_group.kubernetes_workers.id
  referenced_security_group_id = aws_security_group.kubernetes_workers.id
  from_port         = 8443
  ip_protocol       = "tcp"
  to_port           = 8443
}


resource "aws_vpc_security_group_ingress_rule" "nodeport_svc_2" {
  security_group_id = aws_security_group.kubernetes_workers.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 30131
  ip_protocol       = "tcp"
  to_port           = 30131
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_workers_ec2_connect" {
  security_group_id = aws_security_group.kubernetes_workers.id
  cidr_ipv4         = "35.180.112.80/29"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_workers_from_runner" {
  security_group_id = aws_security_group.kubernetes_workers.id
  cidr_ipv4         = "172.31.32.99/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_out" {
  security_group_id = aws_security_group.kubernetes_workers.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
