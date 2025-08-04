# output "fcknat_asg_names" {
#   value = {
#     for k, m in module.fck-nat :
#     k => element(split("/", m.autoscaling_group_arn), 1)
#   }
# }
