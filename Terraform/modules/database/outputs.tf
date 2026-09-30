output "db_private_ip" {
  value       = aws_instance.mysql_db.private_ip
  description = "Private IP of the MySQL instance — use this to connect from web servers"
}