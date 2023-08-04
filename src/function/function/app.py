import json
import os, requests

from typing import Any, MutableMapping, Optional, Dict

from falcon import (
    API,
    HTTPBadRequest,
    Request,
    Response,
)


class Verify:
    def __init__(self):
        self.debug_mode = bool(os.environ.get("DEBUG"))

    def on_post(self, request: Request, response: Response, type: str):
        """
        ---
        summary: Verify API
        parameters:
        - name: type
          in: path
          description: Request type
          required: true
          schema:
            type: string
        responses:
          200:
            description: Verify output
            content:
              application/json:
                schema: VerifyRequest
          400:
            description: Verify error
            content:
              application/json:
                schema: ErrorSchema
        """

        if self.debug_mode:
            print(f"Verify: type={type}")

        if type == "example":
            response.media = self.verify_example()
        else:
            raise HTTPBadRequest(description="Unknown Verify request type")

    def verify_example(self) -> dict:
        return {"status": "Ok"}
