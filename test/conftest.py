# File: conftest.py
# Register command line argument for the test
def pytest_addoption(parser):
    parser.addoption(
        '--api-gw-url', action='store', default='', help='Base API Gateway URL'
    )
