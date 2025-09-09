# tests/test_client.py
"""
Tests for EODData client
"""

import pytest
from unittest.mock import Mock, patch
from eoddata import EODDataClient, EODDataError, EODDataAPIError, EODDataAuthError


class TestEODDataClient:

    def test_client_initialization(self):
        client = EODDataClient(api_key="test_key")
        assert client.api_key == "test_key"
        assert client.base_url == "https://api.eoddata.com"
        assert client.timeout == 30

    @patch('eoddata.client.requests.Session.request')
    def test_successful_request(self, mock_request):
        mock_response = Mock()
        mock_response.ok = True
        mock_response.status_code = 200
        mock_response.json.return_value = {"test": "data"}
        mock_request.return_value = mock_response

        client = EODDataClient(api_key="test_key")
        result = client._request("GET", "/test")

        assert result == {"test": "data"}
        mock_request.assert_called_once()

    @patch('eoddata.client.requests.Session.request')
    def test_auth_error(self, mock_request):
        mock_response = Mock()
        mock_response.ok = False
        mock_response.status_code = 401
        mock_request.return_value = mock_response

        client = EODDataClient(api_key="invalid_key")

        with pytest.raises(EODDataAuthError):
            client._request("GET", "/test")

    @patch('eoddata.client.requests.Session.request')
    def test_not_found_error(self, mock_request):
        mock_response = Mock()
        mock_response.ok = False
        mock_response.status_code = 404
        mock_request.return_value = mock_response

        client = EODDataClient(api_key="test_key")

        with pytest.raises(EODDataAPIError, match="Resource not found"):
            client._request("GET", "/nonexistent")

    @patch('eoddata.client.requests.Session.request')
    def test_rate_limit_error(self, mock_request):
        mock_response = Mock()
        mock_response.ok = False
        mock_response.status_code = 429
        mock_request.return_value = mock_response

        client = EODDataClient(api_key="test_key")

        with pytest.raises(EODDataAPIError, match="Rate limit exceeded"):
            client._request("GET", "/test")

    def test_lazy_loading_properties(self):
        client = EODDataClient(api_key="test_key")

        # Properties should be None initially
        assert client._metadata is None
        assert client._exchanges is None

        # Accessing properties should create instances
        metadata = client.metadata
        exchanges = client.exchanges

        assert client._metadata is not None
        assert client._exchanges is not None

        # Subsequent accesses should return same instances
        assert client.metadata is metadata
        assert client.exchanges is exchanges

    def test_context_manager(self):
        with EODDataClient(api_key="test_key") as client:
            assert isinstance(client, EODDataClient)
