import json
import os
import responses, requests
import boto3
from io import StringIO
import pytest
from unittest.mock import Mock, patch, call

from falcon import HTTPBadRequest

from .code import Code, get_from_address, get_ses_client, get_sns_client, get_ssm_client
from .util_mock import set_up_mock_request

from unittest.mock import Mock, patch

from botocore.stub import Stubber

class TestCode:
    def test_get_sns_client(self):
        result = get_sns_client()
        assert str(type(result)) == str(type(boto3.client("sns", "ap-southeast-2")))

    def test_get_ses_client(self):
        result = get_ses_client()
        assert str(type(result)) == str(type(boto3.client("ses", "ap-southeast-2")))

    def test_get_ssm_client(self):
        result = get_ssm_client()
        assert str(type(result)) == str(type(boto3.client("ssm", "ap-southeast-2")))

    def test_generate_otp(self):
        otp = Code().generate_otp()
        assert type(otp) == str and len(otp) == 6


    def test_invalid_json(self):
        resource = Code()

        request = set_up_mock_request(payload="{123")

        with pytest.raises(HTTPBadRequest) as exc_info:
            resource.on_post(request, Mock())

        assert exc_info.value.description.startswith("Invalid json")

    def test_invalid_body_no_keys(self):
        resource = Code()

        request = set_up_mock_request(payload=json.dumps({}))

        with pytest.raises(HTTPBadRequest) as exc_info:
            resource.on_post(request, Mock())

        assert exc_info.value.description.startswith("Neither 'email' or 'phone' was specified in the request body")

    def test_invalid_body_both_keys(self):
        resource = Code()

        request = set_up_mock_request(payload=json.dumps({
            "email": "test@example.com",
            "phone": "+61412341234",
        }))

        with pytest.raises(HTTPBadRequest) as exc_info:
            resource.on_post(request, Mock())

        assert exc_info.value.description.startswith("Must specify either 'email' or 'phone' in the request body")

    @patch("function.code.get_ssm_client")
    def test_get_from_address(self, mock_get_ssm_client):
        ssm_client = boto3.client("ssm", region_name="ap-southeast-2")
        mock_get_ssm_client.return_value = ssm_client
        stubber = Stubber(ssm_client)

        expected_kwargs = {
            "Name": "/infra/cognito-from-email-address-aus"
        }
        stubber.add_response("get_parameter", {
            "Parameter": {"Value": "test@example.com"}
        }, expected_kwargs)
        stubber.activate()

        assert get_from_address() == "test@example.com"

        stubber.assert_no_pending_responses()
        stubber.deactivate()

    @patch("function.code.Code.generate_otp")
    @patch("function.code.get_ses_client")
    @patch("function.code.get_from_address")
    def test_send_email_success(self, mock_get_from_address, mock_get_ses_client, mock_generate_otp):
        mock_get_from_address.return_value = "testfrom@example.com"

        ses_client = boto3.client("ses", region_name="ap-southeast-2")
        mock_get_ses_client.return_value = ses_client
        stubber = Stubber(ses_client)

        expected_kwargs = {
            "Source": "testfrom@example.com",
            "Destination": {"ToAddresses": ["test@example.com"]},
            "Message": {
                "Subject": {"Data": "Your Household Capital verification code"},
                "Body": {
                    "Text": {
                        "Data": "Your verification code is 123456. Do not share this code with anyone."
                    }
                },
            },
        }
        stubber.add_response("send_email", {"MessageId": "testid123"}, expected_kwargs)
        stubber.activate()

        resource = Code()
        resource.debug_mode = True

        mock_generate_otp.return_value = "123456"

        request = set_up_mock_request(payload=json.dumps({
            "email": "test@example.com",
        }))

        response = Mock()
        resource.on_post(request, response)

        stubber.assert_no_pending_responses()
        stubber.deactivate()

        assert response.media == {
            "code": "123456",
        }

    @patch("function.code.Code.generate_otp")
    @patch("function.code.get_sns_client")
    def test_send_phone_success(self, mock_get_sns_client, mock_generate_otp):
        sns_client = boto3.client("sns", region_name="ap-southeast-2")
        mock_get_sns_client.return_value = sns_client
        stubber = Stubber(sns_client)

        expected_kwargs = {
            "Message": "Your verification code is 123456. Do not share this code with anyone.",
            "PhoneNumber": "+61412341234",
        }
        stubber.add_response("publish", {}, expected_kwargs)
        stubber.activate()

        resource = Code()
        resource.debug_mode = True

        mock_generate_otp.return_value = "123456"

        request = set_up_mock_request(payload=json.dumps({
            "phone": "+61412341234",
        }))

        response = Mock()
        resource.on_post(request, response)

        stubber.assert_no_pending_responses()
        stubber.deactivate()

        assert response.media == {
            "code": "123456",
        }