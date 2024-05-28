from flask import Flask, render_template
import yfinance as yf
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import io
import base64
import os

# Define static folder for css files
STATIC_DIR = os.path.abspath('./static')

# app = Flask(__name__) # to make the app run without any
app = Flask(__name__, static_folder=STATIC_DIR)

img = io.BytesIO()

# Define the stock names
stock_names = ['AAPL', 'GOOGL', 'MSFT']  # Replace with your desired stock symbols

# Perform stock market analysis for each stock name
stock_data = {}
for stock_name in stock_names:
    # Fetch stock data
    data = yf.download(stock_name, start='2022-01-01', end='2023-01-01')
    print(data)

# Calculate 50-day moving average
    data['MA50'] = data['Close'].rolling(window=50).mean()

    # Calculate 200-day moving average
    data['MA200'] = data['Close'].rolling(window=200).mean()

    # Calculate RSI
    delta = data['Close'].diff(1)
    gain = delta.where(delta > 0, 0)
    loss = -delta.where(delta < 0, 0)
    avg_gain = gain.rolling(window=14).mean()
    avg_loss = loss.rolling(window=14).mean()
    rs = avg_gain / avg_loss
    data['RSI'] = 100 - (100 / (1 + rs))

    # Calculate MACD
    data['26ema'] = data['Close'].ewm(span=26).mean()
    data['12ema'] = data['Close'].ewm(span=12).mean()
    data['MACD'] = data['12ema'] - data['26ema']

    # Calculate Bollinger Bands
    data['20ma'] = data['Close'].rolling(window=20).mean()
    data['20sd'] = data['Close'].rolling(window=20).std()
    data['UpperBB'] = data['20ma'] + (data['20sd']*2)
    data['LowerBB'] = data['20ma'] - (data['20sd']*2)

    # Visualize the data and indicators
    plt.figure(figsize=(12,6))
    plt.plot(data['Close'], label='Close Price')
    plt.plot(data['MA50'], label='50-day MA')
    plt.plot(data['MA200'], label='200-day MA')
    plt.title('Stock Analysis for ' + stock_name)
    plt.legend()
    plt.savefig(img, format='png')
    img.seek(0)
    plot_url = base64.b64encode(img.getvalue()).decode()
    plt.close()

    # Store the data and plot URL
    stock_data[stock_name] = {
        'data': data[['RSI', 'MACD']].tail().to_html(),
        'plot_url': 'data:image/png;base64,{}'.format(plot_url)
    }

@app.route('/')
def index():
    return render_template('stock_analysis.html', stock_data=stock_data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=True)