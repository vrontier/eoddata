# EODData Python Client

A pythonic client library for accessing [EODData.com](https://eoddata.com) data API giving access to historical market data and fundamental data of various stock exchanges around the world, including the US, Canada, Europe. The package echos the EODData REST API and adds API call accounting with quotas so that you can track your usage.

Any API call beside Metadata requires an API key, which you will receive by registering yourself as a user. A free tier exists, which allows one to access US equities, crypto currencies, global indices and forex pairs (daily request limit). For more information about their products and services, please check their website.

I am a long-time subscriber of EODData and have created this library for my own use. I have decided to open source it so that others can benefit from it.

## Installation

Due to a pending request regarding its naming, the package is not yet available at [PyPI](https://pypi.org) production but only at [Test PyPI](https://test.pypi.org).

You can install the production version package from there for testing purposes:
```bash
pip install eoddata-api
```

Please note that this package has a different version (due to development and publishing tests) than the one on PyPI will have. But you can uninstall it once the package at PyPI will be available as the functionality will be the same.

## API Key

In order to use the EODData API, you will need to register yourself as a user. You can choose between a free tier and a paid subscription. Please check [their website](https://eoddata.com/products/default.aspx) for more information.
Once you have registered yourself as a user, you will find your API key in your account area. You can use it to authenticate your requests.

The client will look for your API key in the environment variable `EODDATA_API_KEY` and terminate if not set.

## Quick Start

```python
"""
Basic usage examples for EODData client
"""

import os
from resource import RLIMIT_CPU

from eoddata import EODDataClient, EODDataError, AccountingTracker


def main():
    # Get API key from environment
    api_key = os.getenv("EODDATA_API_KEY")
    if not api_key:
        print("Please set EODDATA_API_KEY environment variable")
        return

    # Create and enable API call accounting
    accounting = AccountingTracker(debug=True)
    accounting.start()

    # EODData STANDARD membership
    limit_60s = 10
    limit_24h = 100

    # Enable quotas for API key (CORRECTED - now properly per API key)
    accounting.enable_quotas(api_key, calls_60s=limit_60s, calls_24h=limit_24h)

    # Initialize client with optional debug mode
    # Set debug=True to see detailed request/response logging
    debug_mode = os.getenv("EODDATA_DEBUG", "").lower() in ('true', '1', 'yes')
    client = EODDataClient(api_key=api_key, debug=debug_mode, accounting=accounting)

    if debug_mode:
        print("Debug mode enabled - detailed request/response logging will be shown")

    try:
        # Get metadata (no auth required)
        print("Exchange Types:")
        for exchange_type in client.metadata.exchange_types():
            print(f"  {exchange_type['name']}")

        print("\nSymbol Types:")
        for symbol_type in client.metadata.symbol_types():
            print(f"  {symbol_type['name']}")

        # Get exchanges
        print("\nFirst 5 Exchanges:")
        exchanges = client.exchanges.list()
        for exchange in exchanges[:5]:
            print(f"  {exchange['code']}: {exchange['name']} ({exchange['country']})")

        # Get symbols for NASDAQ
        print("\nFirst 5 NASDAQ Symbols:")
        symbols = client.symbols.list("NASDAQ")
        for symbol in symbols[:5]:
            print(f"  {symbol['code']}: {symbol['name']}")

        # Get quote for AAPL
        print("\nAAPL Latest Quote:")
        quote = client.quotes.get("NASDAQ", "AAPL")
        print(f"  Date: {quote['dateStamp']}")
        print(f"  Open: ${quote['open']:.2f}")
        print(f"  High: ${quote['high']:.2f}")
        print(f"  Low: ${quote['low']:.2f}")
        print(f"  Close: ${quote['close']:.2f}")
        print(f"  Volume: {quote['volume']:,}")

    except EODDataError as e:
        print(f"Error: {e}")

    accounting.stop()
    print(accounting.summary())
    print("\nBasic usage test completed successfully!\n")

if __name__ == "__main__":
    main()
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

## Debugging

The client includes a `debug` flag that can be used to enable verbose logging. Setting the environment variable `EODDATA_DEBUG` to `true` will enable debug logging.

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

## API Call Accounting and Quota Management

The EODData client includes comprehensive API call tracking and quota enforcement to help you monitor and manage your API usage effectively. This is particularly useful for managing rate limits and avoiding unexpected overages.

### Features

- **Call Tracking**: Track total calls, calls in the last 60 seconds, and calls in the last 24 hours
- **Quota Enforcement**: Set and enforce limits to prevent exceeding your plan limits
- **Per-Operation Tracking**: Monitor usage by specific API operations
- **Persistent Storage**: Save and load tracking data between sessions
- **Summary Reports**: Generate human-readable usage reports

### Basic Usage

```python
from eoddata import EODDataClient, AccountingTracker

# Create and start accounting tracker
accounting = AccountingTracker(debug=True)
accounting.start()

# Set quotas based on your EODData plan
# Standard plan: 10 calls/60s, 100 calls/24h
accounting.enable_quotas(
    api_key="your_api_key",
    calls_60s=10,
    calls_24h=100
)

# Use client with accounting
client = EODDataClient(api_key="your_api_key", accounting=accounting)

# Make API calls - they're automatically tracked
exchanges = client.exchanges.list()
quotes = client.quotes.get("NASDAQ", "AAPL")

# Check current usage
accounting.check_quota("your_api_key")  # Raises OutOfQuotaError if exceeded

# Generate usage report
print(accounting.summary())

# Save tracking data
accounting.save_to_file("usage_data.json")

# Stop tracking
accounting.stop()
```

### Sample Output

The `accounting.summary()` method provides a detailed breakdown of your API usage:

```
EODData Call Accounting Summary
========================================

API Key: XXXX****XXXX
  Global Totals:
    Total calls: 5
    60s calls: 5
    24h calls: 5
  Operations:
    List_ExchangeType:
      Total calls: 1
      60s calls: 1
      24h calls: 1
    List_SymbolType:
      Total calls: 1
      60s calls: 1
      24h calls: 1
    List_Exchange:
      Total calls: 1
      60s calls: 1
      24h calls: 1
    List_Symbol:
      Total calls: 1
      60s calls: 1
      24h calls: 1
    Get_Quote:
      Total calls: 1
      60s calls: 1
      24h calls: 1
```

### Advanced Features

#### Persistent Data Storage

```python
# Save current state
filename = accounting.save_to_file()  # Auto-generates timestamped filename
# Or specify custom filename
accounting.save_to_file("my_usage_data.json")

# Load previous state
accounting.load_from_file("my_usage_data.json")
```

#### Reset Tracking

```python
# Reset all counters while keeping quotas
accounting.reset()
```

#### Quota Violation Handling

```python
from eoddata import OutOfQuotaError

try:
    client.quotes.get("NASDAQ", "AAPL")
except OutOfQuotaError as e:
    print(f"Quota exceeded: {e.message}")
    print(f"Quota type: {e.quota_type}")  # 'total', 'calls_60s', or 'calls_24h'
```

### EODData Plan Integration

The accounting system works seamlessly with EODData's subscription plans:

- **Free Tier**: Set conservative limits for testing
- **Standard Plan**: 10 calls/60s, 100 calls/24h
- **Professional Plan**: Higher limits based on your subscription
- **Enterprise**: Custom limits

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
- requests 2.32+

## License

[MIT License](LICENSE)
