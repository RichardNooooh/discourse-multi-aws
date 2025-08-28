
variable "project" {
  type      = string
  sensitive = true
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

variable "force_destroy" {
  type        = bool
  description = "Determines whether or not the buckets are forcibly deleted. Useful for development environments."
  default     = false
}
