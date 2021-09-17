data "archive_file" "ecs_logs_sender" {
  type        = "zip"
  source_dir  = "./../lambda_funcs/ecs_logs_sender"
  output_path = "./../lambda_funcs/outputs/ecs_logs_sender.zip"
}

resource "aws_lambda_function" "ecs_logs_sender" {
  filename         = data.archive_file.ecs_logs_sender.output_path
  source_code_hash = data.archive_file.ecs_logs_sender.output_base64sha256
  function_name    = "ecs_logs_sender"
  role             = aws_iam_role.foo.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  memory_size      = 512
  timeout          = 30
  environment {
    variables = {
      "LOG_GROUP"       = "/ecs/example-cluster"
      "LOG_STREAM_BASE" = "ecs/example-service/"
      "TOPIC_ARN"       = aws_sns_topic.main.arn
    }
  }
}

resource "aws_lambda_permission" "intergarate_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_logs_sender.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_target.ecs_events.arn
}

resource "aws_lambda_function_event_invoke_config" "fix_retry_attempts" {
  function_name = aws_lambda_function.ecs_logs_sender.function_name
  destination_config {
    on_failure {
      destination = aws_sns_topic.main.arn
    }
  }
  maximum_retry_attempts  = 2
}
