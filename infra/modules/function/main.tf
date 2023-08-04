# -------------------------------------
# Function
# -------------------------------------
resource "aws_lambda_function" "function" {
  function_name    = var.name
  filename         = data.archive_file.function.output_path
  role             = aws_iam_role.function.arn
  handler          = "function.event.handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 256
  source_code_hash = data.archive_file.function.output_base64sha256

  environment {
    variables = {
      DEBUG = var.debug
    }
  }

  tracing_config {
    mode = "Active"
  }

  layers = ["arn:aws:lambda:ap-southeast-2:580247275435:layer:LambdaInsightsExtension:18"]

  lifecycle {
    ignore_changes = [
      filename
    ]
  }

  depends_on = [
    aws_cloudwatch_log_group.function,
    aws_iam_role.function,
    aws_iam_role_policy_attachment.function,
    aws_iam_role_policy_attachment.x_ray_tracing,
    aws_iam_role_policy_attachment.cloudwatch_insight,
    aws_iam_role_policy.ssm_access
  ]

  tags = merge(var.tags, { "Name" = var.name })
}

data "archive_file" "function" {
  type        = "zip"
  source_dir  = "../output/src/function/function"
  output_path = "../output/function.zip"
}

# -------------------------------------
# Logs
# -------------------------------------
resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 14

  tags = merge(var.tags, { "Name" = var.name })
}

# -------------------------------------
# Role
# -------------------------------------
data "aws_iam_policy_document" "function" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "function" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.function.json

  tags = merge(var.tags, { "Name" = "${var.name}-role" })
}

resource "aws_iam_role_policy_attachment" "function" {
  role       = aws_iam_role.function.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "x_ray_tracing" {
  role       = aws_iam_role.function.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_insight" {
  role       = aws_iam_role.function.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

# -------------------------------------
# SSM Access Policy
# -------------------------------------

resource "aws_iam_role_policy" "ssm_access" {
  name = "${aws_iam_role.function.name}-ssm-access"
  role = aws_iam_role.function.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
