output "s3_uploads_bucket_arn" {
  description = "ARN of uploads bucket"
  value       = module.s3_uploads.s3_bucket_arn
}

output "s3_backups_bucket_arn" {
  description = "ARN of backups bucket"
  value       = module.s3_backups.s3_bucket_arn
}

output "s3_telemetry_bucket_arn" {
  description = "ARN of telemetry bucket"
  value       = module.s3_telemetry.s3_bucket_arn
}

output "s3_telemetry_bucket_id" {
  description = "Name of telemetry bucket"
  value       = module.s3_telemetry.s3_bucket_id
}

