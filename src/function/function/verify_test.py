import json
import os
import responses, requests
from io import StringIO
import pytest
from unittest.mock import Mock, patch, call

from falcon import HTTPBadRequest

from .verify import Verify


class TestVerify:
    def test_invalid_type(self):
        # setup
        resource = Verify()

        # execute
        with pytest.raises(HTTPBadRequest) as exc_info:
            resource.on_post(Mock(), Mock(), "invalid")

        # verify
        assert exc_info.value.description.startswith("Unknown Verify request type")

    @responses.activate
    def test_example(self):
        # setup
        resource = Verify()
        response = Mock()

        # execute
        resource.on_post(Mock(), response, "example")

        # verify
        assert response.media["status"] == "Ok"

    @patch("builtins.print")
    @responses.activate
    def test_example_debug(self, printer):
        # setup
        os.environ["DEBUG"] = "1"
        resource = Verify()

        # execute
        resource.on_post(Mock(), Mock(), "example")

        # verify
        assert printer.mock_calls == [call("Verify: type=example")]

        # clean
        os.environ["DEBUG"] = ""
