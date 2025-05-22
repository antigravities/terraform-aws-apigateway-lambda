locals {
  safe_name = replace(var.name, "/[^a-zA-Z0-9-_]/", "_")
}

variable "name" {
  type        = string
  description = "The domain name of the API Gateway"
}

variable "adjust_cloudwatch_settings" {
  type        = bool
  description = "Whether to adjust the CloudWatch settings for API Gateway logs (optional)"
  default     = false
}

variable "role_permissions_boundary" {
  type        = string
  description = "The ARN of the IAM policy that is used to set the permissions boundary for the API Gateway role (optional)"
  default     = null
}

variable "throttling_burst_limit" {
  type        = number
  description = "The maximum API request burst limit"
  default     = 50
}

variable "throttling_rate_limit" {
  type        = number
  description = "The maximum API request steady-state limit"
  default     = 100
}

variable "role_arn" {
  type        = string
  description = "The ARN of the IAM role that is used by the backing lambda. If none is provided a new role will be created that has the BasicExecutionRole."
  default     = null
}

variable "runtime" {
  type        = string
  description = "The runtime of the lambda function"
  default     = "nodejs22.x"
}

variable "handler" {
  type        = string
  description = "The handler of the lambda function"
  default     = "index.handler"
}

variable "source_code" {
  type        = string
  description = "The source of the lambda function"
  default     = "lambda.zip"
}

variable "timeout" {
  type        = number
  description = "The timeout of the lambda function"
  default     = 10
}

variable "architectures" {
  type        = list(string)
  description = "The architectures of the lambda function"
  default     = ["arm64"]
}

variable "environment" {
  type        = map(string)
  description = "The environment variables of the lambda function"
  default     = {}
}

variable "memory_size" {
  type        = number
  description = "Max memory to give to function"
  default     = 128
}

variable "layer" {
  type        = string
  description = "The ARN of the lambda layer to use"
  default     = null
}

output "gateway_target_domain_name" {
  value = aws_apigatewayv2_domain_name.domain.domain_name_configuration[0].target_domain_name
}

output "gateway_ids" {
  value = {
    api_id   = aws_apigatewayv2_api.gateway.id
    stage_id = aws_apigatewayv2_stage.stage.id
  }
}
