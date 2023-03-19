# File: test_api_endpoint.py
# Test live API endpoint
# Takes --api-gw-url input
import pytest
import json
import requests


# Get --api-gw-url parameter in
@pytest.fixture
def api_gw_url(request):
    return request.config.getoption('--api-gw-url')


# Append required API endpoint locations
@pytest.fixture
def get_visitors_api_url(api_gw_url):
    api_url = f'{api_gw_url}/getVisitors'
    return api_url


@pytest.fixture
def update_visitors_api_url(api_gw_url):
    api_url = f'{api_gw_url}/updateVisitors'
    return api_url


# Test response to an invalid request
# Expect a HTTP 403 response
def test_invalid_request(update_visitors_api_url):
    response = requests.post(update_visitors_api_url)

    assert response.status_code == 403


# Test live response to a getVisitors request
# Expect a HTTP 200 with non-empty body
def test_get_visitors_api_endpoint_response(get_visitors_api_url):
    response = requests.get(get_visitors_api_url)
    response_json = json.loads(response.text)
    print(response_json)

    assert response.status_code == 200
    assert response is not None


# Test live response to a updateVisitros request
# Expect a HTTP 200, increased 'views' after successive call
def test_update_visitors_api_endpoint_response(update_visitors_api_url):
    response1 = requests.get(update_visitors_api_url)
    response2 = requests.get(update_visitors_api_url)

    assert response1.status_code == 200
    assert response2.status_code == 200

    response1_views = response1.json()['views']['N']
    response2_views = response2.json()['views']['N']
    assert response2_views > response1_views
