import boto3
import os
import json
import uuid

dynamodb = boto3.resource("dynamodb")
# SNS topic lives in us-east-1 — always use that region regardless of where Lambda runs
sns = boto3.client("sns", region_name="us-east-1")


def handler(event, context):
    region = os.environ["REGION"]

    # Write greeting log to regional DynamoDB table
    table = dynamodb.Table(os.environ["TABLE_NAME"])
    table.put_item(Item={
        "id":     str(uuid.uuid4()),
        "region": region,
        "source": "Lambda",
    })

    # Publish verification payload to Unleash live SNS topic
    sns.publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Message=json.dumps({
            "email":  os.environ["EMAIL"],
            "source": "Lambda",
            "region": region,
            "repo":   os.environ["REPO"],
        }),
    )

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "region":  region,
            "message": "Hello from Lambda!",
        }),
    }
