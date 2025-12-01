locals {
  name = "${var.project}-${var.environment}-fcknat"

  pub_by_az = zipmap(var.azs, var.public_subnets)
  rtb_by_az = zipmap(var.azs, var.private_route_table_ids)

  tags = merge(
    {
      Project     = var.project,
      Environment = var.environment
      Role        = "nat"
      Managed     = "true"
    },
    var.extra_tags
  )
}

module "fck_nat" {
  for_each = local.pub_by_az

  source = "git::https://github.com/RaJiska/terraform-aws-fck-nat.git?ref=v1.3.0"
  name   = "${local.name}-${each.key}"

  instance_type = var.fcknat_instance

  vpc_id    = var.vpc_id
  subnet_id = each.value

  update_route_tables = true
  route_tables_ids = {
    for id in [local.rtb_by_az[each.key]] : id => id
  }

  ha_mode            = true
  use_spot_instances = false # too unreliable
  # credit_specification = "standard"

  ssh_key_name = var.ssh_key_name
  use_ssh      = var.ssh_key_name != null

  # cloud_init_parts = [
  #   {
  #     content = "text/x-shellscript"
  #     content_type = templatefile("${path.module}/scripts/install_node_exporter.tftpl", {
  #       # DATA_VOLUME_ID = aws_ebs_volume.vmdata.id
  #     })
  #   }
  # ]


  tags = local.tags
}
