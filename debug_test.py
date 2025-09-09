"""
Debug test script to demonstrate verbose logging functionality
"""

import os
import sys
import logging

# Add src to path for local testing
sys.path.insert(0, 'src')

from eoddata import EODDataClient, EODDataError


def main():
    """Test the debug functionality"""
    # Get API key from environment
    api_key = os.getenv("EODDATA_API_KEY")
    if not api_key:
        print("Please set EODDATA_API_KEY environment variable")
        print("You can do this by running: export EODDATA_API_KEY='your_api_key'")
        return

    print("Testing EODData client with debug mode enabled...")
    print("=" * 60)

    # Initialize client with debug mode
    client = EODDataClient(api_key=api_key, debug=True)

    try:
        print("\n1. Testing metadata API (should work without authentication):")
        exchange_types = client.metadata.exchange_types()
        print(f"Retrieved {len(exchange_types)} exchange types")

        print("\n2. Testing exchanges API:")
        exchanges = client.exchanges.list()
        print(f"Retrieved {len(exchanges)} exchanges")

        print("\n3. Testing quotes API (this might fail if API key is invalid):")
        try:
            quote = client.quotes.get("NASDAQ", "AAPL")
            print(f"Retrieved quote for AAPL: ${quote.get('close', 'N/A')}")
        except EODDataError as e:
            print(f"Quote API failed: {e}")

    except EODDataError as e:
        print(f"\nAPI Error occurred: {e}")
        print("Check the debug logs above for more details about the failed requests")

    except Exception as e:
        print(f"\nUnexpected error: {e}")


if __name__ == "__main__":
    main()
