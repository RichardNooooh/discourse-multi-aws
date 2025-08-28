locals {
  name = "${var.project}-${var.environment}"

  tags = merge( # TODO refactor this stupid thing
    {
      Project     = var.project,
      Environment = var.environment
    },
    var.extra_tags
  )

  s3_access_log_location = "s3-access-logs/"
}

# ################ #
# S3 Name Suffixes #
# ################ #
resource "random_string" "s3_uploads_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "random_string" "s3_backups_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "random_string" "s3_telemetry_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "random_string" "s3_retention_suffix" {
  length  = 16
  special = false
  upper   = false
}

locals {
  uploads_name   = "${local.name}-uploads-${random_string.s3_uploads_suffix.result}"
  backups_name   = "${local.name}-backups-${random_string.s3_backups_suffix.result}"
  telemetry_name = "${local.name}-telemetry-${random_string.s3_telemetry_suffix.result}"
  retention_name = "${local.name}-retention-${random_string.s3_retention_suffix.result}"
}

# ############## #
# Uploads Bucket #
# ############## #
module "s3_uploads" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v5.4.0"

  bucket        = local.uploads_name
  force_destroy = var.force_destroy

  block_public_acls       = false # "Block public access... new ACLs"
  ignore_public_acls      = false # "Block public access... any ACLs"
  block_public_policy     = true  # "Block public access... new public bucket..."
  restrict_public_buckets = true  # "Block public access... any public bucket..."

  # ACLS are needed
  # https://meta.discourse.org/t/the-bucket-does-not-allow-acls/244093
  # Otherwise, you'll get an error like:
  #   > rake aborted!
  #   > Aws::S3::Errors::AccessControlListNotSupported: The bucket does not allow ACLs
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  # CORS initialized by discourse on rebuild
}

# ############## #
# Backups Bucket #
# ############## #
module "s3_backups" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v5.4.0"
  # TODO setup telemetry configuration to monitor s3 sizes
  bucket        = local.backups_name
  force_destroy = var.force_destroy

  lifecycle_rule = [
    {
      id      = "long-storage"
      enabled = true

      transition = [
        {
          days          = 7
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 100 # minimum: 7 days normal storage + 90 day minimum in Flexible Glacier
      }

      abort_incomplete_multipart_upload_days = 7
    }
  ]
}

# ################ #
# Telemetry Bucket #
# ################ #
module "s3_telemetry" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v5.4.0"

  bucket        = local.obs_name
  force_destroy = var.force_destroy

  attach_elb_log_delivery_policy            = true
  attach_access_log_delivery_policy         = true
  access_log_delivery_policy_source_buckets = ["arn:aws:s3:::${local.retention_name}"] # prevents cyclical dependencies

  lifecycle_rule = [
    {
      id      = "rotate-s3-access-logs"
      enabled = true

      filter = {
        prefix = local.s3_access_log_location
      }

      expiration = {
        days = 7
      }
    }
  ]
}
# TODO add CloudTrail events
# ################ #
# Retention Bucket #
# ################ #
module "s3_retention" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v5.4.0"

  bucket        = local.retention_name
  force_destroy = var.force_destroy

  versioning = {
    enabled = true
  }

  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        # mode probably shouldn't be COMPLIANCE since we may need to delete it earlier (following law enforcement orders)
        mode = "GOVERNANCE"
        days = 365
      }
    }
  }
  # TODO configure logging when ready for observability stack
  # logging = {
  #   target_bucket = module.s3_telemetry.s3_bucket_id
  #   target_prefix = local.s3_access_log_location
  #   target_object_key_format = {
  #     partitioned_prefix = {
  #       partition_date_source = "DeliveryTime"
  #     }
  #   }
  # }
}
