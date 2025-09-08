"""
EODData API Python Client

A pythonic way to access EODData.com historical market data API.
"""

__version__ = "0.1.0"
__author__ = "Mike Quest"

from .client import EODDataClient
from .exceptions import EODDataError, EODDataAPIError, EODDataAuthError

__all__ = ["EODDataClient", "EODDataError", "EODDataAPIError", "EODDataAuthError"]
