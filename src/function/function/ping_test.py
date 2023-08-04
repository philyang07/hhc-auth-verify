import json
import os
from io import StringIO
import pytest
from unittest.mock import Mock, patch, call
from importlib import reload

from falcon import HTTPBadRequest, HTTPForbidden, HTTPInvalidParam

from .ping import Ping


class TestPing:
    @patch("builtins.print")
    def test_ping(self, printer):
        # setup
        response = Mock()
        resource = Ping()

        # execute
        resource.on_get(Mock(), response)

        # verify
        assert response.media["ping"] == "Ok"

    @patch("builtins.print")
    def test_debug(self, printer):
        os.environ["DEBUG"] = "1"
        try:
            import function.ping

            reload(function.ping)

            # setup
            resource = Ping()
            resource.on_get(Mock(), Mock())
        finally:
            del os.environ["DEBUG"]
            reload(function.ping)

        assert printer.mock_calls == [call("PING!")]
