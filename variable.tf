variable "devs" {
  description = "prefix n login"
}

variable "ytoken" {
  description = "yandex cloud token"
  type        = string
  sensitive   = true
}

variable "ycloud" {
  description = "yandex cloud id"
  type        = string
  sensitive   = true
}

variable "yfolder" {
  description = "yandex folder id"
  type        = string
  sensitive   = true
}

variable "y_image" {
  description = "yandex vps image"
  type        = string
  default     = "fd80iibe8asp4inkhuhr"
}

variable "login_user" {
  description = "login user"
  type        = string
  sensitive   = true
}

variable "my_ssh_key" {
  description = "my_ssh_key"
  type        = string
  sensitive   = true
}
