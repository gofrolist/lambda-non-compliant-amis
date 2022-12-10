// terraform backend configuration
terraform {
  backend "s3" {
    // NOTE: bucket needs to be created
    bucket         = "tfstate-dev"
    region         = "us-west-2"
    encrypt        = true
    key            = "dev.tfstate"
    dynamodb_table = "tflock"
  }
}

provider "aws" {
  region  = "us-west-2"
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ses:SendEmail",
      "ses:SendRawEmail",
      "ses:ListVerifiedEmailAddresses"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "NonCompliantAMI_lambda_policy"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "NonCompliantAMI_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.lambda_policy.arn]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/files/lambda.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name                  = "NonCompliantAMI"
  description                    = "NonCompliantAMI lambda"
  role                           = aws_iam_role.lambda_role.arn
  filename                       = data.archive_file.lambda_zip.output_path
  source_code_hash               = data.archive_file.lambda_zip.output_base64sha256
  runtime                        = "python3.9"
  handler                        = "lambda.lambda_handler"
  timeout                        = 10
  reserved_concurrent_executions = 1
  publish                        = true
  tracing_config {
    mode = "Active"
  }
}

# create an EventBridge event rule
resource "aws_cloudwatch_event_rule" "rule" {
  name        = "InvokeLambdaNonCompliantAMI"
  description = "Trigger my Lambda function NonCompliantAMI"
  schedule_expression = "rate(1 hour)"
}

# create an EventBridge event target
resource "aws_cloudwatch_event_target" "target" {
  target_id   = "my-function-target"
  rule        = aws_cloudwatch_event_rule.rule.name
  arn         = aws_lambda_function.lambda.arn
  input       = <<-JSON
  {
    "region": "us-west-2",
    "compliant_amis": ${jsonencode(var.compliant_amis)},
    "email": ${jsonencode(var.email)}
  }
  JSON
}

resource "aws_ses_email_identity" "email" {
  email = var.email
}
