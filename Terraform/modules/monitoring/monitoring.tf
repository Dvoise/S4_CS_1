data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_iam_role" "monitoring_role" {
  name = "monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ec2_describe" {
  name = "ec2-describe-instances"
  role = aws_iam_role.monitoring_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:DescribeInstances"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "monitoring-profile"
  role = aws_iam_role.monitoring_role.name
}

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.monitoring_sg_id]
  iam_instance_profile        = aws_iam_instance_profile.monitoring_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y prometheus wget gnupg apt-transport-https

    cat > /etc/prometheus/prometheus.yml <<'PROM'
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets: ['localhost:9090']
      - job_name: web
        ec2_sd_configs:
          - region: eu-central-1
            port: 9100
            filters:
              - name: tag:Name
                values: ['web-server']
              - name: instance-state-name
                values: ['running']
        relabel_configs:
          - source_labels: [__meta_ec2_instance_id]
            target_label: instance_id
    PROM
    systemctl restart prometheus

    mkdir -p /etc/apt/keyrings
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
    apt-get update -y
    apt-get install -y grafana

    cat > /etc/grafana/provisioning/datasources/prometheus.yml <<'DS'
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://localhost:9090
        isDefault: true
    DS

    systemctl enable grafana-server
    systemctl start grafana-server
  EOF

  tags = {
    Name = "monitoring"
  }
}