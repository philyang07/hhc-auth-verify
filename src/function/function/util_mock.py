from unittest.mock import Mock
from io import StringIO

def set_up_mock_request(payload=""):
    request = Mock()
    
    request.content_length = len(payload)
    request.content_type = "application/json"
    request.stream = StringIO(payload)
    return request
