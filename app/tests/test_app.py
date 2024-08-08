import pytest
import io
import base64
import pandas as pd
from flask import Flask
from flask.testing import FlaskClient
from app import app, fetch_from_mysql  # Replace 'your_app_module' with the actual name of your module

@pytest.fixture
def client() -> FlaskClient:
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index(client: FlaskClient):
    """Test the index route."""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Stock Analysis' in response.data  # Check if the title or some known content is present

def test_fetch_from_mysql():
    """Test the data fetching from MySQL."""
    stock_name = 'AMZN'
    data = fetch_from_mysql(stock_name)
    assert isinstance(data, pd.DataFrame)
    assert not data.empty
    assert 'Date' in data.columns
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
    plt.legend()
    plt.savefig(img, format='png')
    img.seek(0)
    plot_url = base64.b64encode(img.getvalue()).decode()
    plt.close()

    # Check if plot URL is a valid base64 string
    assert plot_url.startswith('iVBORw0KGgo=')

