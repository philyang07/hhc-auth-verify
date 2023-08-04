import json
from dataclasses import dataclass
from typing import Dict

import requests
from falcon import App, Request, Response

from .code import Code
from .verify import Verify
from .ping import Ping


class FunctionApi(App):
    def __init__(self, *args, **kwargs):
        App.__init__(self, *args, **kwargs)
        self.resources = set()

    def add_route(self, uri_template, resource, **kwargs):
        super().add_route(uri_template, resource, **kwargs)
        self.resources.add(resource)


def get_api(is_debug) -> FunctionApi:
    api = FunctionApi(middleware=Logging(is_debug))
    api.add_route("/api/verify/v1/code", Code())
    api.add_route("/api/verify/v1/{type}", Verify())
    api.add_route("/api/verify/v1/ping", Ping())

    return api


@dataclass
class Logging:
    enabled: bool

    def process_resource(self, request: Request, response: Response, resource: object, params: dict):
        if self.enabled:
            print(f'Processing "{request.method}" on "{resource}"')
