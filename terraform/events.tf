resource "aws_cloudwatch_event_rule" "ecs_status" {
  name = "detect_ecs_status_changed"

  event_pattern = jsonencode(
    {
        "source": [
            "aws.ecs"
        ],
        "detail-type": [
            "ECS Task State Change"
        ],
        "detail": {
            "containers": {
                "exitCode": [
                    {
                        "anything-but": 0
                    }
                ]
            },
            "lastStatus": [
                "STOPPED"
            ],
            "stoppedReason": [
                {
                    "anything-but": {
                        "prefix": "Scaling activity initiated by"
                    }
                }
            ]
        }
    }
  )
}

resource "aws_cloudwatch_event_target" "ecs_events" {
  rule      = aws_cloudwatch_event_rule.ecs_status.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.main.arn

  depends_on = [aws_cloudwatch_event_rule.health]
}
