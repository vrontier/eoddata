"""
EODData API Python Client

A pythonic way to access EODData.com historical market data API.
"""

try:
    from importlib.metadata import version
    __version__ = version("eoddata")
except ImportError:
    # Python < 3.8 fallback
    from importlib_metadata import version
    __version__ = version("eoddata")
except Exception:
    # Fallback for development/edge cases
    __version__ = "unknown"

__author__ = "Mike Quest"

from .client import EODDataClient
from .exceptions import EODDataError, EODDataAPIError, EODDataAuthError

__all__ = ["EODDataClient", "EODDataError", "EODDataAPIError", "EODDataAuthError"]
