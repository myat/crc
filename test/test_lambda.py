import boto3
import pytest
from moto import mock_dynamodb
import sys
import json

sys.path.append("..")

DYNAMODB_TABLE_NAME = "visitor_count_table"


@pytest.fixture
def invalid_event():
    invalid_event = {
            "resource": "/{proxy+}",
            "path": "/invalidPath",
            "httpMethod": "GET"
        }
    return invalid_event


@pytest.fixture
def get_visitors_event():
    get_visitors_event = {
            "resource": "/{proxy+}",
            "path": "/getVisitors",
            "httpMethod": "GET"
        }
    return get_visitors_event


@pytest.fixture
def update_visitors_event():
    update_visitors_event = {
            "resource": "/{proxy+}",
            "path": "/updateVisitors",
            "httpMethod": "GET"
        }
    return update_visitors_event


@pytest.fixture(autouse=True)
def set_up():
    with mock_dynamodb():
        dynamodb = boto3.client('dynamodb', region_name='us-east-1')
        mockTable = dynamodb.create_table(
            TableName=DYNAMODB_TABLE_NAME,
            KeySchema=[
                {
                    'AttributeName': 'site_name',
                    'KeyType': 'HASH'
                }
            ],
            AttributeDefinitions=[
                {
                    'AttributeName': 'site_name',
                    'AttributeType': 'S'
                }
            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 1,
                'WriteCapacityUnits': 1
            }
        )

        dynamodb.put_item(
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
        yield dynamodb
        dynamodb = None


def test_invalid_request(invalid_event, set_up):
    from src.lambda_function import lambda_handler
    response = lambda_handler(event=invalid_event, context={})

    assert response['statusCode'] == 400


def test_get_visitors(get_visitors_event, set_up):
    from src.lambda_function import lambda_handler
    response = lambda_handler(event=get_visitors_event, context={})

    assert response['statusCode'] == 200
    assert response['body'] is not None


def test_update_visitors(update_visitors_event, set_up):
    from src.lambda_function import lambda_handler

    response1 = lambda_handler(update_visitors_event, [])
    assert response1['statusCode'] == 200

    response2 = lambda_handler(update_visitors_event, [])
    assert response2['statusCode'] == 200

    response1_views = json.loads(response1['body'])['views']['N']
    response2_views = json.loads(response2['body'])['views']['N']
    assert response2_views > response1_views
