resource "aws_instance" "mysql_db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_blue_id
  vpc_security_group_ids = [var.db_sg_id]
  iam_instance_profile   = var.db_instance_profile_name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y mysql-server

    systemctl enable mysql
    systemctl start mysql

    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    systemctl restart mysql

    mysql -e "CREATE DATABASE IF NOT EXISTS ${var.db_name};"
    mysql -e "CREATE USER IF NOT EXISTS '${var.db_username}'@'%' IDENTIFIED WITH mysql_native_password BY '${var.db_password}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${var.db_name}.* TO '${var.db_username}'@'%';"
    mysql -e "FLUSH PRIVILEGES;"
  EOF
  )

  tags = {
    Name = "self-managed-mysql"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}