
The library uses EODData's [REST-based API](https://api.eoddata.com/scalar/v1) to retrieve data.

# EODData Python Client

A pythonic client library for accessing [EODData.com](https://eoddata.com) data API giving access to historical market data and fundamental data of various stock exchanges around the world, including the US, Canada, Europe.

Any API call beside Metadata requires an API key, which you will receive by registering yourself as a user. A free tier exists, which allows one to access US equities, crypto currencies, global indices and forex pairs (daily request limit). For more information about their products and services, please check their website.

I am a long-time user of EODData and have created this library for my own use. I have decided to open source it so that others can benefit from it.

## Installation

```bash
pip install eoddata
```

## API Key

Once you have registered yourself as a user, you will find your API key in your account area. You can use it to authenticate your requests.

The client will look for your API key in the environment variable `EODDATA_API_KEY` and terminate if not set.

## Quick Start

```python
import os
from eoddata import EODDataClient

# Initialize client with your API key
api_key = os.getenv("EODDATA_API_KEY")
client = EODDataClient(api_key=api_key)

# Get metadata (no auth required)
exchange_types = client.metadata.exchange_types()
symbol_types = client.metadata.symbol_types()

# Get exchanges and symbols
exchanges = client.exchanges.list()
nasdaq_symbols = client.symbols.list("NASDAQ")

# Get quotes
latest_quotes = client.quotes.list_by_exchange("NASDAQ")
aapl_quote = client.quotes.get("NASDAQ", "AAPL")
historical_quotes = client.quotes.list_by_symbol("NASDAQ", "AAPL",
                                                from_date="2024-01-01",
                                                to_date="2024-12-31")

# Get corporate information
company_profile = client.corporate.profile_get("NASDAQ", "AAPL")
dividends = client.corporate.dividends_by_symbol("NASDAQ", "AAPL")
splits = client.corporate.splits_by_symbol("NASDAQ", "AAPL")

# Get fundamental data
fundamentals = client.fundamentals.get("NASDAQ", "AAPL")

# Get technical indicators
technicals = client.technicals.get("NASDAQ", "AAPL")
```

## API Categories

The client is organized into logical categories that mirror the EODData API structure:

- **`client.metadata`** - Exchange types, symbol types, countries, currencies
- **`client.exchanges`** - Exchange listings and information
- **`client.symbols`** - Symbol listings and information
- **`client.quotes`** - Current and historical price data (OHLCV)
- **`client.corporate`** - Company profiles, splits, dividends
- **`client.fundamentals`** - Financial metrics (PE, EPS, etc.)
- **`client.technicals`** - Technical indicators (MA, RSI, etc.)

## Error Handling

The client includes comprehensive error handling:

```python
from eoddata import EODDataClient, EODDataError, EODDataAPIError, EODDataAuthError

try:
    client = EODDataClient(api_key="invalid_key")
    data = client.quotes.get("NASDAQ", "AAPL")
except EODDataAuthError:
    print("Authentication failed - check your API key")
except EODDataAPIError as e:
    print(f"API error: {e}")
except EODDataError as e:
    print(f"General error: {e}")
```

## Context Manager Support

Use the client as a context manager for automatic resource cleanup:

```python
with EODDataClient(api_key=api_key) as client:
    quotes = client.quotes.list_by_exchange("NASDAQ")
```

## EODData REST API Documentation
Since August, 30th 2025 EODData has offered a [REST API](https://api.eoddata.com/) for its subscribers. It offers developers and analysts seamless access to a wide range of financial market data, including:

- Historical end-of-day OHLCV prices
- A wide range of international exchanges with more than 100,000 symbols
- Company profiles and fundamentals
- Over 60 technical indicators
- More than 30 years of historical end-of-day data
- Splits & dividends
- Market metadata, such as exchange and ticker information

## Testing

To run the test suite:
```bash
# Install test dependencies (if not already installed)
pip install pytest pytest-cov

# Run all tests with coverage
pytest tests/ --cov=eoddata --cov-report=term-missing

# Run a specific test
pytest tests/test_client.py::TestEODDataClient::test_client_initialization

# Run integration tests (requires API key)
pytest tests/test_integration.py --run-integration
```

The test suite covers all API endpoints with proper mocking to avoid external dependencies. All tests must pass with 80%+ code coverage before publishing.

### Integration Tests

Integration tests are available to verify the client works with the real EODData API. These tests require a valid API key and are disabled by default.

To run integration tests:
1. Set your API key in the `EODDATA_API_KEY` environment variable or in a `.env` file
2. Run: `pytest tests/test_integration.py --run-integration`

Integration tests will:
- Verify the client can connect to the real API
- Test all API endpoints with actual data
- Handle rate limiting and API errors gracefully

## Requirements

- Python 3.10+
- requests

## License

[MIT License](LICENSE)
