output "alb_dns_name" {
  value       = aws_lb.web_alb.dns_name
  description = "The DNS name of the ALB"
}

output "asg_name" {
  value       = aws_autoscaling_group.terraform_asg.name
  description = "Name of the web tier Auto Scaling Group"
}

output "target_group_name" {
  value       = aws_lb_target_group.web_tg.name
  description = "Name of the ALB target group"
}