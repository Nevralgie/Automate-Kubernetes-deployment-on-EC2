variable "environment" {
  description = "Prod or Dev environment ?"
  type = string
  default = "Dev"
}

variable "control_plane_instance_number" {
  description = "How many controlplane ?"
  type = number
  default = 1
}

variable "worker_instance_number" {
  description = "How many workers ?"
  type = number
  default = 2
}

/*
variable "gitlab_pat_token" {
  type = string
  default = ""
}
*/