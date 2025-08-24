
variable "project" {
  type = string
  sensitive = true
}

variable "region" {
  type = string
}

variable "environment" { # dev or prod, or whatever
  type = string
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
