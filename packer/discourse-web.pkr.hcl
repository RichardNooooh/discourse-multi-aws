packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type = string
}

variable "build_instance" {
  type = string
}

variable "build_volume" {
  type = number
}

variable "aws_region" {
  type = string
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "${var.build_instance}"
  region        = "${var.aws_region}"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.build_volume
    volume_type           = "gp3"
    delete_on_termination = true
  }

  ami_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = var.build_volume
    volume_type = "gp3"
  }
}


build {
  name = "discourse_web"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    script            = "update.sh"
    expect_disconnect = true
  }

  provisioner "file" {
    source       = "discourse_containers/web_only.yml"
    destination  = "/tmp/web_only.yml"
    pause_before = "30s"
  }
  provisioner "file" { # TODO remove
    source      = "discourse_containers/env.yml"
    destination = "/tmp/env.yml"
  }

  provisioner "shell" {
    script = "bootstraper.sh"
  }
}


