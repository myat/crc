# File: test_lambda.py
# Unit test on lambda_function.py with pytest and moto
import boto3
import pytest
import sys
import json
import os
from moto import mock_dynamodb

sys.path.append("..")

DYNAMODB_TABLE_NAME = "visitor_count_table"


@pytest.fixture
def invalid_event():
    invalid_event = {
            "resource": "/{proxy+}",
            "path": "/invalidPath",
            "httpMethod": "GET",
            "headers": {
                "origin": "http://example.com"
            }
        }
    return invalid_event


@pytest.fixture
def get_visitors_event():
    get_visitors_event = {
            "resource": "/{proxy+}",
            "path": "/getVisitors",
            "httpMethod": "GET",
            "headers": {
                "origin": "https://resume.kgmy.at"
            }
        }
    return get_visitors_event


@pytest.fixture
def update_visitors_event():
    update_visitors_event = {
            "resource": "/{proxy+}",
            "path": "/updateVisitors",
            "httpMethod": "GET",
            "headers": {
                "origin": "https://staging.kgmy.at"
            }
        }
    return update_visitors_event


@pytest.fixture
def aws_fake_credentials():
    """Fake credentials for mock usage."""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_KEY'] = 'testing'


@pytest.fixture(autouse=True)
def set_up(aws_fake_credentials):
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

        yield dynamodb, mockTable
        dynamodb = None


# Test response to an invalid request
# Expect a HTTP 400 response
# Expect a correct CORS header in the response
def test_invalid_request(invalid_event, set_up):
    from src.lambda_function import lambda_handler
    response = lambda_handler(event=invalid_event, context={})

    assert response['statusCode'] == 400
    assert response['headers']['Access-Control-Allow-Origin'] != \
        invalid_event['headers']['origin']


# Test response to a getVisitors request
# Expect a HTTP 200 with non-empty body
# Expect a correct CORS header in the response
def test_get_visitors(get_visitors_event, set_up):
    from src.lambda_function import lambda_handler
    response = lambda_handler(event=get_visitors_event, context={})

    assert response['statusCode'] == 200
    assert response['body'] is not None
    assert response['headers']['Access-Control-Allow-Origin'] == \
        get_visitors_event['headers']['origin']


# Test response to a updateVisitros request
# Expect a HTTP 200, increased 'views' after successive call
# Expect correct CORS header in the response
def test_update_visitors(update_visitors_event, set_up):
    from src.lambda_function import lambda_handler

    response1 = lambda_handler(update_visitors_event, [])
    assert response1['statusCode'] == 200
    assert response1['headers']['Access-Control-Allow-Origin'] == \
        update_visitors_event['headers']['origin']

    response2 = lambda_handler(update_visitors_event, [])
    assert response2['statusCode'] == 200
    assert response2['headers']['Access-Control-Allow-Origin'] == \
        update_visitors_event['headers']['origin']

    response1_views = json.loads(response1['body'])['views']['N']
    response2_views = json.loads(response2['body'])['views']['N']
    assert response2_views > response1_views
