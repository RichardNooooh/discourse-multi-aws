
variable "project" {
  type     = string
  nullable = false
}

variable "environment" {
  type     = string
  nullable = false
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "azs" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_route_table_ids" {
  type = list(string)
}

variable "fcknat_instance" {
  type = string
}

variable "ssh_key_name" {
  type      = string
  sensitive = true
  default   = null
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}
