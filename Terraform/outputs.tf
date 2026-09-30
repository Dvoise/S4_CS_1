output "alb_dns_name" {
  value       = module.my_compute.alb_dns_name
  description = "Public URL to access the web app"
}

output "db_private_ip" {
  value       = module.my_database.db_private_ip
  description = "Private IP of the MySQL database"
}

output grafana_url {
  value       = module.my_monitoring.grafana_url
  description = "Public URL for Grafana"
}

output prometheus_url {
  value       = module.my_monitoring.prometheus_url
  description = "Public URL for Prometheus"
}