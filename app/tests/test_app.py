import pytest
from unittest.mock import patch, MagicMock
import pandas as pd
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

@patch('app.fetch_data')
def test_index(mock_fetch, client):
    # Create a mock DataFrame
    mock_data = pd.DataFrame({
        'Date': pd.date_range(start='2023-01-01', end='2023-01-14'),
        'Open': [120.00, 123.00, 126.00, 127.00, 125.00, 124.00, 123.00, 122.00, 124.00, 126.00, 128.00, 130.00, 131.00, 133.00],
        'High': [125.00, 128.00, 130.00, 129.00, 127.00, 126.00, 128.00, 125.00, 127.00, 130.00, 133.00, 135.00, 134.00, 135.00],
        'Low': [119.00, 122.00, 125.00, 124.00, 123.00, 121.00, 120.00, 121.00, 123.00, 125.00, 127.00, 129.00, 130.00, 131.00],
        'Close': [123.00, 126.00, 127.00, 125.00, 124.00, 123.00, 122.00, 124.00, 126.00, 128.00, 130.00, 132.00, 133.00, 135.00],
        'AdjClose': [123.00, 126.00, 127.00, 125.00, 124.00, 123.00, 122.00, 124.00, 126.00, 128.00, 130.00, 132.00, 133.00, 136.00],
        'Volume': [1000000, 1100000, 1200000, 1300000, 1400000, 1500000, 1600000, 1700000, 1800000, 1900000, 2000000, 2100000, 2200000, 2300000]
    })
    mock_data.set_index('Date', inplace=True)

    # Set the return value of the mock function
    mock_fetch.return_value = mock_data

    response = client.get('/')
    assert response.status_code == 200
    assert b'Stock Analysis' in response.data
