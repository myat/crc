import json
import boto3
from botocore.exceptions import ClientError

DYNAMODB_TABLE_NAME = 'visitor_count_table'

GET_RAW_PATH = '/getVisitors'
UPDATE_RAW_PATH = '/updateVisitors'
HTTP_VERB_GET = 'GET'
HTTP_VERB_POST = 'POST'

ALLOWED_ORIGINS_LIST = [
    'https://resume.kgmy.at',
    'https://staging.kgmy.at',
    'https://test.kgmy.at']

client = boto3.client('dynamodb', region_name='us-east-1')


def get_allow_origin(request_origin):
    if request_origin in ALLOWED_ORIGINS_LIST:
        return {'Access-Control-Allow-Origin': request_origin}
    else:
        return {'Access-Control-Allow-Origin': ALLOWED_ORIGINS_LIST[0]}


def initialize_visitor_count_item():
    site_key = {
        'site_name': {
            'S': 'resume.kgmy.at'
        }
    }
    try:
        data = client.get_item(
            TableName=DYNAMODB_TABLE_NAME,
            Key=site_key
        )
        if 'Item' not in data:
            client.put_item(
                TableName=DYNAMODB_TABLE_NAME,
                Item={
                    'site_name': {
                        'S': 'resume.kgmy.at'
                    },
                    'views': {
                        'N': '0'
                    }
                }
            )
    except ClientError as e:
        print(e)
        raise Exception("Failed to initialize table item")


def lambda_handler(event, context):
    origin_header = get_allow_origin(event.get('headers', {}).get('origin'))

    # Initialize the visitor record table
    initialize_visitor_count_item()

    if (event['path'] == GET_RAW_PATH and
            event['httpMethod'] == HTTP_VERB_GET):
        print("Starting request for getVisitors")
        # Call DynamoDB
        data = client.get_item(
            TableName=DYNAMODB_TABLE_NAME,
            Key={
                'site_name': {
                    'S': 'resume.kgmy.at'
                }
            }
        )
        response = {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,GET',
                **origin_header
                },
            'body': json.dumps(data['Item'])
        }

    elif (event['path'] == UPDATE_RAW_PATH and
            event['httpMethod'] == HTTP_VERB_GET):
        print("Starting request for updateVisitors")

        site_key = {
            'site_name': {
                'S': 'resume.kgmy.at'
            }
        }

        # Update DynamoDB
        # Increment the view counter by 1
        data = client.update_item(
            TableName=DYNAMODB_TABLE_NAME,
            Key=site_key,
            UpdateExpression='SET #views=if_not_exists(#views, :init) + :inc',
            ExpressionAttributeNames={
                '#views': 'views'
            },
            ExpressionAttributeValues={
                ':inc': {
                    'N': '1'
                },
                ':init': {
                    'N': '0'
                }
            },
            ReturnValues='UPDATED_NEW'
        )

        response = {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,GET',
                **origin_header
                },
            'body': json.dumps(data['Attributes'])
        }

    else:
        response = {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'OPTIONS,GET',
                **origin_header
                },
            'body': 'Unsupported'
        }

    return response
