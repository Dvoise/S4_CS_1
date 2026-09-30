variable "private_subnet_blue_id" {
  type = string
}
variable "db_sg_id" {
  type = string
}
variable "db_instance_profile_name" {
  type    = string
  default = null
}
variable "db_name" {
  type    = string
  default = "appdb"
}
variable "db_username" {
  type    = string
  default = "admin"
}
variable "db_password" {
  type      = string
  sensitive = true
}   