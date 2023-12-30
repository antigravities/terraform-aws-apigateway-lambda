resource "aws_iam_role" "lambda_role" {
  count = var.role_arn == null ? 1 : 0

  name = "${local.safe_name}-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AllowAssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  permissions_boundary = var.role_permissions_boundary
}

resource "aws_lambda_function" "lambda" {
  function_name    = local.safe_name
  role             = var.role_arn == null ? aws_iam_role.lambda_role[0].arn : var.role_arn
  description      = "${var.name} lambda"
  handler          = var.handler
  runtime          = var.runtime
  publish          = true
  source_code_hash = filebase64sha256(var.source_code)
  filename         = var.source_code
  timeout          = var.timeout
  architectures    = var.architectures

  environment {
    variables = var.environment
  }
}

resource "aws_lambda_permission" "allow_from_apigateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission#specify-lambda-permissions-for-api-gateway-rest-api
  source_arn = "${aws_apigatewayv2_api.gateway.execution_arn}/*/*"
}