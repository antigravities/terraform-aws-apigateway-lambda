# API gateway and certificate

resource "aws_apigatewayv2_api" "gateway" {
  name                         = local.safe_name
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = true
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = var.name
  validation_method = "DNS"
}

resource "aws_apigatewayv2_domain_name" "domain" {
  domain_name = var.name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "mapping" {
  domain_name = aws_apigatewayv2_domain_name.domain.id
  stage       = aws_apigatewayv2_stage.stage.id
  api_id      = aws_apigatewayv2_api.gateway.id
}

resource "aws_apigatewayv2_stage" "stage" {
  name        = "$default"
  api_id      = aws_apigatewayv2_api.gateway.id
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  dynamic "access_log_settings" {
    for_each = var.adjust_cloudwatch_settings ? ["true"] : []

    content {
      destination_arn = aws_cloudwatch_log_group.logs.arn
      format          = "$context.identity.sourceIp $context.identity.caller  $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId $context.extendedRequestId"
    }
  }
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id = aws_apigatewayv2_api.gateway.id

  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  description            = "${var.name} API"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  api_id             = aws_apigatewayv2_api.gateway.id
  route_key          = "ANY /{proxy+}"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

# CloudWatch logs

resource "aws_iam_role" "gw_role" {
  count = var.adjust_cloudwatch_settings ? 1 : 0

  name = "${local.safe_name}-gateway"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AllowAssumeRole"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  ]

  permissions_boundary = var.role_permissions_boundary
}

resource "aws_api_gateway_account" "account" {
  count = var.adjust_cloudwatch_settings ? 1 : 0

  cloudwatch_role_arn = var.adjust_cloudwatch_settings ? aws_iam_role.gw_role[0].arn : null
}