output "wrks_instance_name" {
  value = aws_instance.workers[*].tags
}

output "wrks_instance_pub_ip" {
  value = aws_instance.workers[*].public_ip
}

output "wrks_private_ip" {
  value = aws_instance.workers[*].private_ip
}

output "ctrl_instance_name" {
  value = aws_instance.control_plane[*].tags
}

output "ctl_private_ip" {
  value = aws_instance.control_plane[*].private_ip
}

output "ctl_public_ip" {
  value = aws_instance.control_plane[*].public_ip
}