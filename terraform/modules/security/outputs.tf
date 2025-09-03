output "sg_alb_id" {
  description = "Security Group ID of ALB"
  value       = aws_security_group.alb.id
}

output "sg_web_id" {
  description = "Security Group ID of Web"
  value       = aws_security_group.web.id
}

output "sg_monitor_id" {
  description = "Security Group ID of monitor"
  value       = aws_security_group.monitor.id
}

output "sg_cache_id" {
  description = "Security Group ID of Cache"
  value       = aws_security_group.cache.id
}

output "sg_db_id" {
  description = "Security Group ID of Database"
  value       = aws_security_group.db.id
}

output "cache_iam_instance_arn" {
  description = "ARN of the cache's IAM Instance"
  value       = aws_iam_instance_profile.cache_iam_instance_profile.arn
}

output "webonly_iam_instance_arn" {
  description = "Name of web-only IAM instance profile"
  value       = aws_iam_instance_profile.webonly_iam_instance_profile.arn
}
