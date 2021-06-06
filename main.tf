terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  backend "s3" {
    bucket = "broswen-test-files"
    key    = "terraform/tfgo"
    region = "us-east-1"
  }

}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

resource "aws_sns_topic" "topic" {
  name = "${var.project_name}-${var.stage}-${var.topic_name}"
}

resource "aws_sqs_queue" "queue" {
  name                      = "${var.project_name}-${var.stage}-${var.queue_name}"
  receive_wait_time_seconds = 10
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.topic.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sns_topic_subscription" "topic_subscription" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue.arn
}

resource "aws_iam_role_policy_attachment" "basic_execution_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.printer_role.name
}

resource "aws_iam_role" "printer_role" {
  name = "${var.project_name}-${var.stage}-printer-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  inline_policy {
    name   = "pull_from_sqs"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${aws_sqs_queue.queue.arn}"
    }
  ]
}
EOF
  }
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  depends_on = [
    aws_iam_role.printer_role
  ]
  event_source_arn                   = aws_sqs_queue.queue.arn
  function_name                      = aws_lambda_function.printer_lambda.arn
  enabled                            = true
  batch_size                         = 25
  maximum_batching_window_in_seconds = 10
}

resource "aws_lambda_function" "printer_lambda" {
  filename                       = "./bin/functions.zip"
  function_name                  = "${var.project_name}-${var.stage}-printer"
  role                           = aws_iam_role.printer_role.arn
  handler                        = "bin/printer"
  reserved_concurrent_executions = 1

  source_code_hash = filebase64sha256("./bin/functions.zip")

  runtime = "go1.x"

  environment {
    variables = {
      stage = var.stage
    }
  }
}
