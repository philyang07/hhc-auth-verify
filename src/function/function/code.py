import json
import boto3
import os, requests
import secrets
import string

from falcon import (
    HTTPBadRequest,
    Request,
    Response,
)



def get_ssm_client() -> boto3.client:
    return boto3.client("ssm", region_name="ap-southeast-2")


def get_sns_client() -> boto3.client:
    return boto3.client("sns", region_name="ap-southeast-2")


def get_ses_client() -> boto3.client:
    return boto3.client("ses", region_name="ap-southeast-2")


def get_from_address() -> str:
    return get_ssm_client().get_parameter(Name="/infra/cognito-from-email-address-aus")["Parameter"][
        "Value"
    ]

class Code:
    def __init__(self):
        self.debug_mode = bool(os.environ.get("DEBUG"))

    def on_post(self, request: Request, response: Response):
        if self.debug_mode:
            print(f"Code")

        data = {}
        try:
            if request.content_length:
                data = json.load(request.stream)
                self.handle_data(data, response)
        except json.JSONDecodeError:
            raise HTTPBadRequest(description="Invalid json")

    def handle_data(self, data: dict, response: Response):
        valid_keys = ["email", "phone"]
        if not any(key in data for key in valid_keys):
            raise HTTPBadRequest(description="Neither 'email' or 'phone' was specified in the request body")
        elif all(key in data for key in valid_keys):
            raise HTTPBadRequest(description="Must specify either 'email' or 'phone' in the request body")

        code = self.generate_otp()
        if "email" in data:
            self.send_to_email(data["email"], code)
        else:
            self.send_to_phone(data["phone"], code)

        response.media = {"code": code}

    def generate_otp(self, length: int = 6):
        return "".join(secrets.choice(string.digits) for i in range(length))

    def send_to_phone(self, phone, code):
        if self.debug_mode:
            print(f"Sending code to phone {phone}")

        if not self.validate_phone(phone):
            raise HTTPBadRequest(description="An invalid phone number was provided.")

        get_sns_client().publish(
            Message=f"Your verification code is {code}. Do not share this code with anyone.",
            PhoneNumber=phone,
        )

    def send_to_email(self, email, code):
        if self.debug_mode:
            print(f"Sending code to email {email}")

        if not self.validate_email(email):
            raise HTTPBadRequest(description="An invalid email address was provided.")

        if email:
            get_ses_client().send_email(
                Source=get_from_address(),
                Destination={"ToAddresses": [email]},
                Message={
                    "Subject": {"Data": "Your Household Capital verification code"},
                    "Body": {
                        "Text": {
                            "Data": f"Your verification code is {code}. Do not share this code with anyone."
                        }
                    },
                },
            )

    def validate_phone(self, phone):
        return True

    def validate_email(self, email):
        return True
