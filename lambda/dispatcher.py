import boto3
import os
import json


def handler(event, context):
    ecs = boto3.client("ecs")

    response = ecs.run_task(
        cluster=os.environ["CLUSTER_ARN"],
        launchType="FARGATE",
        taskDefinition=os.environ["TASK_DEF_ARN"],
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets":        [os.environ["SUBNET_ID"]],
                "securityGroups": [os.environ["SG_ID"]],   # required for awsvpc mode
                "assignPublicIp": "ENABLED",                # no NAT gateway needed
            }
        },
    )

    task_arns = [t["taskArn"] for t in response.get("tasks", [])]
    failures  = response.get("failures", [])

    if failures:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "ECS RunTask failed", "failures": failures}),
        }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "message":  "ECS task triggered",
            "region":   os.environ["REGION"],
            "taskArns": task_arns,
        }),
    }
