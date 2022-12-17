import json
import boto3

GET_RAW_PATH = '/getVisitors'
UPDATE_RAW_PATH = '/updateVisitors'
HTTP_VERB_GET = 'GET'

client = boto3.client('dynamodb', region_name='us-east-1')


def lambda_handler(event, context):
    if (event['rawPath'] == GET_RAW_PATH and
            event['requestContext']['http']['method'] == HTTP_VERB_GET):
        print("Starting request for getVisitors")
        # Call DynamoDB
        data = client.get_item(
            TableName='site_visitors',
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
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': 'https://resume.kgmy.at',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
            'body': json.dumps(data['Item'])
        }

    elif (event['rawPath'] == UPDATE_RAW_PATH and
            event['requestContext']['http']['method'] == HTTP_VERB_GET):
        print("Starting request for updateVisitors")

        site_key = {
            'site_name': {
                'S': 'resume.kgmy.at'
            }
        }

        # Update DynamoDB
        # Increment the view counter by 1
        data = client.update_item(
            TableName='site_visitors',
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
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': 'https://resume.kgmy.at',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
            'body': json.dumps(data['Attributes'])
        }

    else:
        response = {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': 'https://resume.kgmy.at',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
            'body': 'Unsupported'
        }

    return response
