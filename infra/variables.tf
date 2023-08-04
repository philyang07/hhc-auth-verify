# -------------------------------------
# General
# -------------------------------------
variable "function" {
  description = "Name of the business function"
  type        = string
}

variable "application" {
  description = "Name of the application"
  type        = string
}

variable "instance" {
  description = "Name of the application instance"
  type        = string
}

variable "sub_domain" {
  description = "Name of the sub domain"
  type        = string
  default     = ""
}

variable "debug" {
  description = "Debug mode"
  type        = bool
  default     = false
}
