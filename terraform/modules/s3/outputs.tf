output "s3_uploads_bucket_arn" {
  description = "ARN of uploads bucket"
  value       = module.s3_uploads.s3_bucket_arn
}

output "s3_backups_bucket_arn" {
  description = "ARN of backups bucket"
  value       = module.s3_backups.s3_bucket_arn
}

output "s3_monitor_bucket_arn" {
  description = "ARN of monitor bucket"
  value       = module.s3_monitor.s3_bucket_arn
}

output "s3_monitor_bucket_id" {
  description = "Name of monitor bucket"
  value       = module.s3_monitor.s3_bucket_id
}

