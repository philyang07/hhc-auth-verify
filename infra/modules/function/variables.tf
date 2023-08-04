variable "name" {
  description = "Function name"
  type        = string
}

variable "api_id" {
  description = "API Gateway ID"
  type        = string
}

variable "api_arn" {
  description = "API Gateway ARN"
  type        = string
}

variable "api_execution_arn" {
  description = "API Gateway execution ARN"
  type        = string
}

variable "api_root_resource_id" {
  description = "API Gateway root resource id"
  type        = string
}

variable "debug" {
  description = "Debug mode"
  type        = bool
}

variable "tags" {
  description = "AWS tags"
  type        = map(any)
}
