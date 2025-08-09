output "sg_alb_id" {
  description = "Security Group ID of ALB"
  value = aws_security_group.alb.id 
}

output "sg_web_id" {
  description = "Security Group ID of Web"
  value = aws_security_group.web.id
}

output "sg_metrics_id" {
  description = "Security Group ID of Metrics"
  value = aws_security_group.metrics.id
}

output "sg_cache_id" {
  description = "Security Group ID of Cache"
  value = aws_security_group.cache.id
}

output "sg_db_id" {
  description = "Security Group ID of Database"
  value = aws_security_group.db.id
}
