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

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "region" {
  type = string
}
