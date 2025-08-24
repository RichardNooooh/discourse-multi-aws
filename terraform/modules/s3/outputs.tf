output "s3_uploads_bucket_arn" {
  description = "ARN of uploads bucket"
  value       = module.s3_uploads.s3_bucket_arn
}

output "s3_backups_bucket_arn" {
  description = "ARN of backups bucket"
  value       = module.s3_backups.s3_bucket_arn
}

output "s3_metrics_bucket_arn" {
  description = "ARN of metrics bucket"
  value       = module.s3_metrics.s3_bucket_arn
}

