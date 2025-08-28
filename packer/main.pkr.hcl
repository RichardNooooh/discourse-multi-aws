packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_prefix}-${var.environment}-${local.timestamp}"
  instance_type = "${var.build_instance}"
  region        = "${var.aws_region}"

  vpc_id               = "${var.vpc_id}"
  subnet_id            = "${var.subnet_id}"
  security_group_id    = "${var.security_group_id}"
  iam_instance_profile = "${var.iam_instance_profile_name}"
  ssh_interface        = "session_manager"

  source_ami_filter {
    filters = {
      name                = "ubuntu-minimal/images/*/ubuntu-noble-24.04-arm64-minimal-*"
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

  provisioner "file" {
    source      = "discourse_setup/db_init.sql"
    destination = "/tmp/db_init.sql"
  }
  provisioner "shell" {
    script            = "update.sh"
    expect_disconnect = true
    env = {
      DB_PASSWORD="${var.db_password}"
    }
  }

  provisioner "file" {
    source       = "discourse_setup/web_only.yml"
    destination  = "/tmp/web_only.yml"
    pause_before = "30s"
  }
  provisioner "file" { # TODO remove
    source      = "discourse_setup/env.yml"
    destination = "/tmp/env.yml"
  }

  provisioner "shell" {
    script = "bootstraper.sh"
  }
}


