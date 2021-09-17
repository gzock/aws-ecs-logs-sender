import os
import json
import boto3

from logging import getLogger, basicConfig, INFO, DEBUG

from modules.ecs_event_result import EcsEventResult

LOG_GROUP=os.environ["LOG_GROUP"]
LOG_STREAM_BASE=os.environ["LOG_STREAM_BASE"]
TOPIC_ARN=os.environ["TOPIC_ARN"]

MESSAGE_TEMPLATE = """
    ECS Task execution failed.
    See the execution log below.

    ###########################
    %s
    ###########################
"""

def lambda_handler(event, context):
  basicConfig(
    format="[%(asctime)s] %(name)s %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
  )
  getLogger().setLevel(INFO)
  logger = getLogger(__name__)

  logger.debug("event payload: %s" % event)
  result = EcsEventResult(event)
  logger.info("executed ecs task exit code: %s, container_fullname: %s, container_cmd: %s" \
      % (result.exit_code, result.container_fullname, result.container_cmd))

  logger.info("gathering logs process start.")

  target_log_stream = LOG_STREAM_BASE + result.event["taskArn"].split("/")[-1]
  logger.info("target log stream path: %s" % target_log_stream)
  
  logs = boto3.client("logs")
  all_logs = []
  args = {
    "logGroupName": LOG_GROUP,
    "logStreamName": target_log_stream,
    "startFromHead": True
  }
  logger.debug("cloudwatch get_log_events arguments: %s" % args)

  while(1):
    log_data = logs.get_log_events(**args)
    logger.debug("got raw log_data: %s" % log_data)

    if not log_data["events"]:
      break
    args.update({ "nextToken": log_data["nextForwardToken"] })
    all_logs.extend(log_data["events"])

  logger.info("gathered all logs.")
  message_body = [ item["message"] for item in all_logs ]
  logger.debug("message body: %s" % message_body)
  
  sns = boto3.client("sns")
  logger.info("publish alert. using sns topic arn: %s" % TOPIC_ARN)
  res = sns.publish(
    TopicArn=TOPIC_ARN,
    Message=MESSAGE_TEMPLATE % "\n".join(message_body),
    Subject="[ERROR_ALERT] '%s' ECS Task Execution Failed..." % result.container_fullname
  )
  logger.info("processing done. response: %s" % res)
  
  return {
    "statusCode": 200,
    "body": json.dumps("processing succeeded.")
  }
