resource "aws_instance" "control_plane" {
  count         = var.control_plane_instance_number
  ami           = "ami-0326f9264af7e51e2"
  instance_type = var.environment == "Prod" ? "t2.2xlarge" : "t3.large"
  key_name      = "Pjpro_key"
  subnet_id                   = aws_subnet.sub_1_ec2_lb.id
  vpc_security_group_ids      = [aws_security_group.kubernetes_controlplane.id]
  associate_public_ip_address = true

  #user_data = file("${path.module}/setup.sh")

  tags = {
    Name = "controlplane_${count.index + 1}"
    role = "Master"
    environment = var.environment
  }
}

resource "aws_instance" "workers" {
  count = var.worker_instance_number
  ami           = "ami-0326f9264af7e51e2"
  instance_type = var.environment == "Prod" ? "t2.2xlarge" : "t3.large"
  key_name      = "Pjpro_key"
  subnet_id                   = aws_subnet.sub_1_ec2_lb.id
  vpc_security_group_ids      = [aws_security_group.kubernetes_workers.id]
  associate_public_ip_address = true

  #user_data = file("${path.module}/setup.sh")

  tags = {
    Name = "kube_worker_${count.index + 1}"
    role = "Worker"
    environment = var.environment
  }
}