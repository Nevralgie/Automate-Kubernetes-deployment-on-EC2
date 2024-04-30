variable "environment" {
  description = "Prod or Dev environment ?"
  type = string
  default = "Dev"
}

variable "control_plane_instance_number" {
  description = "How many controlplane ?"
  type = number
  default = 2
}

variable "worker_instance_number" {
  description = "How many controlplane ?"
  type = number
  default = 4
}
