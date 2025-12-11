variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "cluster_name" {
  type    = string
  default = "my-idp.k8s.local"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_size" {
  type    = string
  default = "t3.small"
}

variable "master_size" {
  type    = string
  default = "t3.medium"
}
