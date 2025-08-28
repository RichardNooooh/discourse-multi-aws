
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

# ############## #
# Network Module #
# ############## #
variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

# ######### #
# S3 Module #
# ######### #
variable "s3_telemetry_bucket_id" { # TODO test sensitive
  type = string
}

# ########## #
# SSL Module #
# ########## #
variable "acm_certificate_arn" {
  type = string
}

variable "cloudflare_zone_id" {
  type      = string
  sensitive = true
}

# ############### #
# Security Module #
# ############### #
variable "webonly_iam_instance_arn" {
  type = string
}

variable "sg_web_id" {
  type = string
}

# #################### #
# Image ID from Packer #
# #################### #
variable "webonly_image_id" { # specified by command line?
  type = string
}

# #################### #
# Environment-Specific #
# #################### #
variable "webonly_instance_type" {
  type = string
}

# ####### #
# Toggles #
# ####### #
variable "cloudflare_proxied" {
  type    = bool
  default = true
}