locals {
  name = "${var.project}-${var.environment}-monitor"
  tags = merge(
    {
      Project     = var.project,
      Environment = var.environment
      Role        = "monitor"
      Managed     = "true"
    },
    var.extra_tags
  )
}


resource "aws_ebs_volume" "vmdata" { # TODO check these parameters
  availability_zone = aws_instance.monitor.availability_zone
  size              = 128
  type              = "st1"
  encrypted         = true
  tags              = local.tags
}


resource "aws_volume_attachment" "vmdata_att" { # TODO check deletion protection
  device_name = "/dev/sdf"                      # /dev/sd[bcde] are used by some ephemeral volumes - aws recommends /dev/sd[f-p] for data
  volume_id   = aws_ebs_volume.vmdata.id
  instance_id = aws_instance.monitor.id
}

resource "aws_instance" "monitor" {
  ami           = var.ami_id
  instance_type = var.instance_type

  user_data = templatefile("${path.module}/scripts/user_data.tftpl", {
    DATA_VOLUME_ID = aws_ebs_volume.vmdata.id
  })
}

resource "aws_route53_record" "monitor" {
  zone_id         = var.hosted_zone_id
  name            = var.record_name
  type            = "A"
  ttl             = 30
  records         = ["0.0.0.0"]
  allow_overwrite = true

  lifecycle {
    ignore_changes = [records] # Tofu won’t revert instance-set IPs
  }
}
