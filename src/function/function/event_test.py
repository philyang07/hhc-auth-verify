import json
import os
import pytest
from unittest.mock import patch, call
from importlib import reload


class TestEvent:
    def test_integration(self):
        try:
            from function.event import handler

            response = handler(
                {
                    "path": "/api/verify/v1/ping",
                    "headers": {},
                    "body": "{}",
                    "requestContext": {},
                    "queryStringParameters": {},
                    "httpMethod": "GET",
                    "isBase64Encoded": False,
                },
                None,
            )
        finally:
            print("Integration OK")

        assert response["statusCode"] == 200

    @patch("builtins.print")
    def test_debug(self, printer):
        os.environ["DEBUG"] = "1"
        try:
            import function.event

            reload(function.event)
            with patch("function.event.handle_request", return_value={"body": "data", "headers": {}}):
                from function.event import handler

                handler({"request": "request_data"}, None)
        finally:
            del os.environ["DEBUG"]
            reload(function.event)

        assert printer.mock_calls == [
            call('{"request": "request_data"}'),
            call('{"body": "data", "headers": {"Access-Control-Allow-Origin": "*"}}'),
        ]
