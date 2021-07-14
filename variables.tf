
variable "private_key_path" {
  default = ""
}

variable "bucket_name_prefix" {
  default = ""
}

variable "environment_tag" {
  default = "Dev"
}

variable "project_tag" {
  default = ""
}

variable "ec2_instance_type" {
  default = "t2.micro"
}

variable "s3_bucket_name" {
  default = ""
}

variable "allocated_storage" {
  default = 10
}

variable "engine" {
  default = "mysql"
}

variable "engine_version" {
  default = "8.0"
}

variable "db_instance_class" {
  default = "db.t2.micro"
}

variable "db_name" {
  default = ""
}

variable "username" {
  default = ""
}

variable "password" {
  default = ""
}
