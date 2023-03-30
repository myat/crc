# File: conftest.py
# Register command line argument for the test
def pytest_addoption(parser):
    parser.addoption(
        '--api-gw-domain',
        action='store',
        default='',
        help='Base API gateway domain'
    )
