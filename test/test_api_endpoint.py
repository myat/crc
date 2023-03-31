# File: test_api_endpoint.py
# Test live API endpoint
# Takes --api-gw-domain input
import pytest
import requests


# Get --api-gw-domain parameter in
@pytest.fixture
def api_gw_domain(request):
    return request.config.getoption('--api-gw-domain')


# Append required API endpoint locations
@pytest.fixture
def get_visitors_api_url(api_gw_domain):
    api_url = f'https://{api_gw_domain}/getVisitors'
    return api_url


@pytest.fixture
def update_visitors_api_url(api_gw_domain):
    api_url = f'https://{api_gw_domain}/updateVisitors'
    return api_url


# Test response to an invalid request
# Expect a HTTP 403 response
def test_invalid_request(update_visitors_api_url):
    response = requests.post(update_visitors_api_url)

    assert response.status_code == 403


# Test live response to a getVisitors request
# Expect a HTTP 200 with non-empty body
# Expect a default allowed domain in CORS header
def test_get_visitors_api_endpoint_response(get_visitors_api_url):
    response = requests.get(get_visitors_api_url)

    assert response is not None
    assert response.status_code == 200
    assert response.headers['Access-Control-Allow-Origin'] == \
        "https://resume.kgmy.at"


# Test live response to a updateVisitros request
# Expect a HTTP 200, increased 'views' after successive call
# Expect a default allowed domain in CORS header
def test_update_visitors_api_endpoint_response(update_visitors_api_url):
    response1 = requests.get(update_visitors_api_url)
    response2 = requests.get(update_visitors_api_url)

    assert response1.status_code == 200
    assert response1.headers['Access-Control-Allow-Origin'] == \
        "https://resume.kgmy.at"

    assert response2.status_code == 200
    assert response1.headers['Access-Control-Allow-Origin'] == \
        "https://resume.kgmy.at"

    response1_views = response1.json()['views']['N']
    response2_views = response2.json()['views']['N']
    assert response2_views > response1_views
