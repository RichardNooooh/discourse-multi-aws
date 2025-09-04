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

source "amazon-ebs" "ubuntu" { # TODO deal with excess AMIs...
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
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
    source      = "container_setup/db_init.sql"
    destination = "/tmp/db_init.sql"
  }

  provisioner "shell" {
    script = "scripts/update.sh"
    env = {
      DB_PASSWORD = "${var.DB_PASSWORD}"
      NODE_EXPORTER_VERSION = "${var.node_exporter_version}"
    }

    expect_disconnect = true
  }

  provisioner "shell" {
    script = "scripts/create_alb_ip_trust.sh"
    env = {
      ALB_SUBNETS_LIST = join(",", var.alb_subnet_ips)
    }
  }

  provisioner "shell" {
    script = "scripts/create_secrets.sh"
    env = {
      HOSTNAME            = "${var.HOSTNAME}" # TODO need to configure this to work with dev environment as well
      DEVELOPER_EMAILS    = "${var.DEVELOPER_EMAILS}"
      SMTP_ADDRESS        = "${var.SMTP_ADDRESS}"
      SMTP_PORT           = "${var.SMTP_PORT}"
      SMTP_USER_NAME      = "${var.SMTP_USER_NAME}"
      SMTP_PASSWORD       = "${var.SMTP_PASSWORD}"
      DB_PASSWORD         = "${var.DB_PASSWORD}"
      S3_UPLOADS_BUCKET   = "${var.S3_UPLOADS_BUCKET}"
      S3_BACKUPS_BUCKET   = "${var.S3_BACKUPS_BUCKET}"
      MAXMIND_ACCOUNT_ID  = "${var.MAXMIND_ACCOUNT_ID}"
      MAXMIND_LICENSE_KEY = "${var.MAXMIND_LICENSE_KEY}"
    }
  }

  provisioner "file" {
    source       = "container_setup/web_only.yml"
    destination  = "/tmp/web_only.yml"
  }

  provisioner "shell" {
    script = "scripts/bootstraper.sh"
  }
}


