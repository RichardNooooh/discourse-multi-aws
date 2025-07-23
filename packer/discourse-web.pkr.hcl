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

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "t2.small" # TODO check
  region        = "us-west-2"
  source_ami_filter { # TODO add more storage (maybe 15 GB?)
    filters = {
      name                = "ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name = "discourse_web"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    script = "update.sh"
    expect_disconnect = true
  }

  provisioner "file" {
    source      = "discourse_containers/web_only.yml"
    destination = "/tmp/web_only.yml"
    pause_before = "30s"
  }
  provisioner "file" {
    source      = "discourse_containers/env.yml"
    destination = "/tmp/env.yml"
  }

  provisioner "shell" {
    script = "bootstraper.sh"
  }
}


