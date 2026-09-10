import base64
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.hashes import SHA256
from utils.config import PrivateKey
from dataclasses import dataclass


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


class FormSubmissionDecrypter:

    def decrypt(
        encrypted_submission: EncryptedFormSubmission, private_key: PrivateKey
    ) -> str:
        try:
            pem_key = serialization.load_pem_private_key(
                private_key.key.encode(), password=None, backend=default_backend()
            )

            oaep_padding = padding.OAEP(
                mgf=padding.MGF1(algorithm=SHA256()),
                algorithm=SHA256(),
                label=None,
            )

            decrypted_key = pem_key.decrypt(
                base64.b64decode(encrypted_submission.encrypted_key),
                oaep_padding,
            )

            decrypted_nonce = pem_key.decrypt(
                base64.b64decode(encrypted_submission.encrypted_nonce),
                oaep_padding,
            )

            decrypted_auth_tag = pem_key.decrypt(
                base64.b64decode(encrypted_submission.encrypted_auth_tag),
                oaep_padding,
            )

            encrypted_data = base64.b64decode(encrypted_submission.encrypted_responses)

            cipher = Cipher(
                algorithms.AES(decrypted_key),
                modes.GCM(decrypted_nonce, decrypted_auth_tag),
                backend=default_backend(),
            )

            decryptor = cipher.decryptor()

            decrypted_data = decryptor.update(encrypted_data) + decryptor.finalize()

            return decrypted_data.decode("utf-8")
        except Exception as exception:
            raise Exception("Failed to decrypt form submission") from exception
