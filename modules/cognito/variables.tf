variable "project_name" {
  type = string
}

variable "email" {
  type = string
}

variable "temp_password" {
  type      = string
  sensitive = true
}
