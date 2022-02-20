variable "privatekeyname" {
  type        = string
  default     = "default_privkey"
  description = "name for private key being made"
}

variable "adminusername" {
  type    = string
  default = "foo"
}

variable "ipaddress" {
  type        = string
  description = "your public ip for ssh access"
}