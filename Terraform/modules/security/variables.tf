variable "vpc_id" {
    description = "The ID of the VPC where the security groups will be created"
    type        = string
}

variable "my_ip_cidr" {
    description = "The CIDR block of the user's IP address for SSH access"
    type        = string
}