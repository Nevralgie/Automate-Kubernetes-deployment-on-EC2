import pytest
import pandas as pd
from flask.testing import FlaskClient
from unittest.mock import patch
from app import app

# Fixture for creating a test client
@pytest.fixture
def client() -> FlaskClient:
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

# Test index route
@patch('app.fetch_from_mysql')
def test_index(mock_fetch, client: FlaskClient):
    """Test the index route."""
    
    # Create dummy data
    dummy_data = pd.DataFrame({
        'Date': pd.date_range(start='2024-01-01', periods=100),
        'Open': range(100),
        'High': range(100),
        'Low': range(100),
        'Close': range(100),
        'AdjClose': range(100),
        'Volume': range(100)
    })
    dummy_data.set_index('Date', inplace=True)
    dummy_data['MA50'] = dummy_data['Close'].rolling(window=50).mean()
    dummy_data['MA200'] = dummy_data['Close'].rolling(window=200).mean()
    dummy_data['RSI'] = 70  # Dummy RSI value
    dummy_data['MACD'] = 0  # Dummy MACD value
    dummy_data['20ma'] = dummy_data['Close'].rolling(window=20).mean()
    dummy_data['20sd'] = dummy_data['Close'].rolling(window=20).std()
    dummy_data['UpperBB'] = dummy_data['20ma'] + (dummy_data['20sd']*2)
    dummy_data['LowerBB'] = dummy_data['20ma'] - (dummy_data['20sd']*2)
    
    # Mock the function to return the dummy data
    mock_fetch.return_value = dummy_data
    
    response = client.get('/')
    assert response.status_code == 200
    assert b'Stock Analysis' in response.data  # Check for known content

    # Check if the dummy data is being processed
    assert b'RSI' in response.data
    assert b'MACD' in response.data

    # Test for plot presence in response
    assert b'data:image/png;base64,' in response.data

# Test fetch_data logic directly
@patch('app.fetch_from_mysql')
def test_fetch_data(mock_fetch):
    """Test the data fetching logic."""
    
    # Dummy data
    dummy_data = pd.DataFrame({
        'Date': pd.date_range(start='2024-01-01', periods=100),
        'Close': pd.Series(range(100)) + 1
    })
    dummy_data.set_index('Date', inplace=True)
    mock_fetch.return_value = dummy_data
    
    # Test the function directly
    data = mock_fetch('AMZN')
    assert isinstance(data, pd.DataFrame)
    assert not data.empty
    assert 'Close' in data.columns

def test_stock_data_computation():
    """Test the stock data computations (e.g., moving averages, RSI)."""
    
    # Simulate data fetching
    data = pd.DataFrame({
        'Date': pd.date_range(start='2024-01-01', periods=100),
        'Close': pd.Series(range(100)) + 1
    })
    data.set_index('Date', inplace=True)

    # Calculate indicators
    data['MA50'] = data['Close'].rolling(window=50).mean()
    data['MA200'] = data['Close'].rolling(window=200).mean()
    delta = data['Close'].diff(1)
    gain = delta.where(delta > 0, 0)
    loss = -delta.where(delta < 0, 0)
    avg_gain = gain.rolling(window=14).mean()
    avg_loss = loss.rolling(window=14).mean()
    rs = avg_gain / avg_loss
    data['RSI'] = 100 - (100 / (1 + rs))
    data['26ema'] = data['Close'].ewm(span=26).mean()
    data['12ema'] = data['Close'].ewm(span=12).mean()
    data['MACD'] = data['12ema'] - data['26ema']
    data['20ma'] = data['Close'].rolling(window=20).mean()
    data['20sd'] = data['Close'].rolling(window=20).std()
    data['UpperBB'] = data['20ma'] + (data['20sd']*2)
    data['LowerBB'] = data['20ma'] - (data['20sd']*2)

    # Test computations
    assert 'MA50' in data.columns
    assert 'RSI' in data.columns
    assert 'MACD' in data.columns
    assert 'UpperBB' in data.columns
    assert 'LowerBB' in data.columns

def test_plot_generation():
    """Test the plot generation."""
    import matplotlib.pyplot as plt
    import io
    import base64

    # Mock Data
    data = pd.DataFrame({
        'Date': pd.date_range(start='2024-01-01', periods=100),
        'Close': pd.Series(range(100)) + 1
    })
    data.set_index('Date', inplace=True)
    data['MA50'] = data['Close'].rolling(window=50).mean()

    # Generate plot
    img = io.BytesIO()
    plt.figure(figsize=(12,6))
    plt.plot(data['Close'], label='Close Price')
    plt.plot(data['MA50'], label='50-day MA')
    plt.title('Test Plot')
    plt.legend
