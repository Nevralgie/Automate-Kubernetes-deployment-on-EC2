output "wrks_instance_name" {wrks_instance_name
  value = aws_instance.workers[*].tags
}

output "ctrl_instance_name" {
  value = aws_instance.control_plane[*].tags
}

output "private_ip" {
  value = aws_instance.control_plane[*].private_ip
}

output "private_ip" {
  value = aws_instance.control_plane[*].public_ip
}