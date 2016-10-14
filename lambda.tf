provider "aws" {
  region = "eu-west-1"
}

resource "aws_iam_role" "iam_for_lambda_es" {
    name = "iam_for_lambda_es"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "test_policy" {
    name = "test_policy"
    role = "${aws_iam_role.iam_for_lambda_es.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:*"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "elasticbeanstalk:Describe*",
        "autoscaling:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "healthcheck_lambda" {
    filename = "lambda_function_payload.zip"
    function_name = "healthcheck_lambda"
    role = "${aws_iam_role.iam_for_lambda_es.arn}"
    handler = "lambda.lambda_handler"
    runtime = "python2.7"
    source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
    # enable access to protected HTTP endpoints
    vpc_config = {
      # subnets the EC2 instances are running in
      subnet_ids = ["subnet-12345678", "subnet-a2345678", "subnet-71234568"]
      # lambda SG, grant access for this on EC2 level
      security_group_ids = ["sg-12345678"]
    }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_healthcheck" {
    statement_id = "AllowExecutionFromCloudWatch-call_healthcheck"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.healthcheck_lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_minute.arn}"
}

resource "aws_cloudwatch_event_rule" "every_minute" {
    name = "every_minute"
    description = "Fires every minute"
    schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "healthcheck_every_minute" {
    rule = "${aws_cloudwatch_event_rule.every_minute.name}"
    arn = "${aws_lambda_function.healthcheck_lambda.arn}"
}
