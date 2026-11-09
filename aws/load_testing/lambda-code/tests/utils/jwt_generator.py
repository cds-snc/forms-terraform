import jwt
import time
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from utils.config import PrivateKey


class JwtGenerator:

    @staticmethod
    def generate(
        identity_provider_url: str,
        private_key: PrivateKey,
    ) -> str:
        try:
            current_time = int(time.time())
            pem_key = serialization.load_pem_private_key(
                private_key.key.encode(), password=None, backend=default_backend()
            )

            headers = {"kid": private_key.keyId, "alg": "RS256"}

            claims = {
                "iat": current_time,
                "iss": private_key.userId or private_key.clientId,
                "sub": private_key.userId or private_key.clientId,
                "aud": identity_provider_url,
                "exp": current_time + 3600,
            }

            jwt_signed_token = jwt.encode(
                claims, pem_key, algorithm="RS256", headers=headers
            )

            return jwt_signed_token

        except Exception as exception:
            raise Exception("Failed to generate signed JWT") from exception
