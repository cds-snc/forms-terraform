from dataclasses import dataclass
from enum import Enum

@dataclass
class PrivateApiKey:
    key_id: str
    key: str
    user_or_client_id: str

    @staticmethod
    def from_json(json_object: dict) -> "PrivateApiKey":
        return PrivateApiKey(
            key_id=json_object["keyId"],
            key=json_object["key"],
            user_or_client_id=json_object.get("userId") or json_object.get("clientId"),
        )

@dataclass
class EncryptedFormSubmission:
    encrypted_responses: str
    encrypted_key: str
    encrypted_nonce: str
    encrypted_auth_tag: str

    @staticmethod
    def from_json(json_object: dict) -> "EncryptedFormSubmission":
        return EncryptedFormSubmission(
            encrypted_responses=json_object["encryptedResponses"],
            encrypted_key=json_object["encryptedKey"],
            encrypted_nonce=json_object["encryptedNonce"],
            encrypted_auth_tag=json_object["encryptedAuthTag"],
        )
