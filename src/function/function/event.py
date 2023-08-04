import json
import os

from serverless_wsgi import handle_request
from .api import get_api


debug_mode = bool(os.environ.get("DEBUG"))
api = get_api(debug_mode)


def handler(event: dict, context):
    if debug_mode:
        print(json.dumps(event))

    response = handle_request(api, event, context)
    if response.get("headers"):
        response["headers"]["Access-Control-Allow-Origin"] = "*"
    else:
        response["headers"] = {"Access-Control-Allow-Origin": "*"}

    if debug_mode:
        print(json.dumps(response))

    return response
