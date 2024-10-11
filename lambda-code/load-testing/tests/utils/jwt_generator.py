import jwt
import time

from dataclasses import dataclass
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from utils.data_structures import PrivateApiKey

class JwtGenerator:

    @staticmethod
    def generate(
        identity_provider_url: str,
        private_api_key: PrivateApiKey,
    ) -> str:
        try:
            current_time = int(time.time())
            private_key = serialization.load_pem_private_key(
                private_api_key.key.encode(), password=None, backend=default_backend()
            )

            headers = {"kid": private_api_key.key_id, "alg": "RS256"}

            claims = {
                "iat": current_time,
                "iss": private_api_key.user_or_client_id,
                "sub": private_api_key.user_or_client_id,
                "aud": identity_provider_url,
                "exp": current_time + 3600,
            }

            jwt_signed_token = jwt.encode(
                claims, private_key, algorithm="RS256", headers=headers
            )

            return jwt_signed_token

        except Exception as exception:
            raise Exception("Failed to generate signed JWT") from exception