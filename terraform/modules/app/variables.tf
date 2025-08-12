
variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "hostname" {
  type = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type = string
  sensitive = true
}
