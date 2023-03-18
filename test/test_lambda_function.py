# File: test_lambda_function.py
from moto import mock_dynamodb
import unittest
import boto3
import json
import sys
sys.path.append("..")

DYNAMODB_TABLE_NAME = 'visitor_count_table'


@mock_dynamodb
class TestLambdaFunction(unittest.TestCase):

    # Set up necessary table for the test
    def setUp(self):
        """ Create database resource and mock table. """
        self.dynamodb = boto3.client('dynamodb', region_name='us-east-1')
        self.mockTable = self.dynamodb.create_table(
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

        self.dynamodb.put_item(
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

    def tearDown(self):
        self.dynamodb = None

    # Test if the mock table is ready
    def test_if_mock_table_exists(self):
        """ Test if mock table is ready """
        mockTable_name = self.mockTable['TableDescription']['TableName']
        self.assertIn(DYNAMODB_TABLE_NAME, mockTable_name)

    # Test for an invalid request and expected HTTP 400 response
    def test_lambda_handler_invalid_request(self):
        """ Test handler response to an invalid request. """

        event = {
            "resource": "/{proxy+}",
            "path": "/invalidPath",
            "httpMethod": "GET"
        }

        from src.lambda_function import lambda_handler

        response = lambda_handler(event, [])
        self.assertEqual(400, response['statusCode'])

    # Test for getVisitors request.
    # Pass if HTTP 200 and body is not empty.
    def test_lambda_handler_get_request(self):
        """ Test handler response to a getVisitors request. """

        event = {
            "resource": "/{proxy+}",
            "path": "/getVisitors",
            "httpMethod": "GET"
        }

        from src.lambda_function import lambda_handler

        response = lambda_handler(event, [])
        self.assertEqual(200, response['statusCode'])
        self.assertIsNotNone(response['body'])

    # Test for updateVisitors requests
    # Pass if HTTP 200, a subsequent request gets a higher view count.
    def test_lambda_handler_update_request(self):
        """ Test handler response to an counter update request. """

        event = {
            "resource": "/{proxy+}",
            "path": "/updateVisitors",
            "httpMethod": "GET"
        }

        from src.lambda_function import lambda_handler

        response1 = lambda_handler(event, [])
        self.assertEqual(200, response1['statusCode'])

        response2 = lambda_handler(event, [])
        self.assertEqual(200, response2['statusCode'])

        response1_views = json.loads(response1['body'])['views']['N']
        response2_views = json.loads(response2['body'])['views']['N']
        self.assertGreater(response2_views, response1_views)


if __name__ == '__main__':
    unittest.main()
