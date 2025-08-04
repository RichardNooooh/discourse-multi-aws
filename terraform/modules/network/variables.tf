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
