"""
Basic usage examples for EODData client
"""

import os
from eoddata import EODDataClient, EODDataError


def main():
    # Get API key from environment
    api_key = os.getenv("EODDATA_API_KEY")
    if not api_key:
        print("Please set EODDATA_API_KEY environment variable")
        return

    # Initialize client with optional debug mode
    # Set debug=True to see detailed request/response logging
    debug_mode = os.getenv("EODDATA_DEBUG", "").lower() in ('true', '1', 'yes')
    client = EODDataClient(api_key=api_key, debug=debug_mode)

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


if __name__ == "__main__":
    main()
