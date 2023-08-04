import os

from falcon import (
    Request,
    Response,
)


debug_mode = bool(os.environ.get("DEBUG"))


class Ping:
    def on_get(self, request: Request, response: Response):
        if debug_mode:
            print("PING!")

        response.media = {"ping": "Ok"}
        response.set_header("X-Content-Type-Options", "nosniff")
        response.set_header("cache-control", "no-cache, no-store, must-revalidate")
