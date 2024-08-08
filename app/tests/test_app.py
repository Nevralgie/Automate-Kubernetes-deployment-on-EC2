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
        'Date': pd.date_range(start='2022-01-01', end='2023-01-01'),
        'Close': [100, 101, 102, 103, 104]
    })
    mock_data.set_index('Date', inplace=True)

    # Set the return value of the mock function
    mock_fetch.return_value = mock_data

    response = client.get('/')
    assert response.status_code == 200
    assert b'Stock Analysis' in response.data

