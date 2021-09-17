resource "aws_sns_topic" "main" {
  name = "example-notification"
}

resource "aws_sns_topic_policy" "email" {
  arn    = aws_sns_topic.main.arn
  policy = data.aws_iam_policy_document.main.json
}

resource "aws_sns_topic_subscription" "target" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = "example@example.com"
}

data "aws_iam_policy_document" "main" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.myself.account_id]
    }
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [aws_sns_topic.main.arn]
    sid       = "__default_statement_ID"
  }
  statement {
    actions = ["SNS:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "cloudwatch.amazonaws.com"]
    }
    resources = [aws_sns_topic.main.arn]
    sid       = "Intergrate-EventBridge-to-SNS"
  }
}
