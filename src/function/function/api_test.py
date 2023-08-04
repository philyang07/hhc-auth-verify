import pytest
from unittest.mock import Mock, patch

import requests
from falcon import HTTPError, Response

from .api import (
    FunctionApi,
    Logging,
    get_api,
)


class TestFunctionApi:
    def test_add_route(self):
        api = get_api(False)
        resource = Mock()
        api.add_route("/resource", resource)
        assert resource in api.resources


class TestLogging:
    @patch("builtins.print")
    def test_logging_enabled(self, printer):
        request = Mock(method="GET")
        Logging(True).process_resource(request, Response(), "method", {})
        printer.assert_called_once_with('Processing "GET" on "method"')

    @patch("builtins.print")
    def test_logging_disabled(self, printer):
        request = Mock(method="GET")
        Logging(False).process_resource(request, Response(), "method", {})
        printer.assert_not_called()
