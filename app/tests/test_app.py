import pytest
from unittest.mock import patch, MagicMock
import pandas as pd
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

@patch('mysql.connector.connect')
def test_index(mock_connect, client):
    # Create a mock connection object
    mock_conn = MagicMock()

    # Create a mock cursor object
    mock_cursor = MagicMock()

    # Set the return value of the mock cursor's fetchall method
    mock_cursor.fetchall.return_value = [
        ('2022-01-01', 100, 101, 99, 100, 100, 1000),
        ('2022-01-02', 101, 102, 100, 101, 101, 1100),
        # Add more rows as needed
    ]

    # Set the return value of the mock connection's cursor method
    mock_conn.cursor.return_value = mock_cursor

    # Set the return value of the mock connect function
    mock_connect.return_value = mock_conn

    response = client.get('/')
    assert response.status_code == 200
    assert b'Stock Analysis' in response.data
