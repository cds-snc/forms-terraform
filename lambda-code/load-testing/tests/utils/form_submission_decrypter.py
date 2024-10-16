import base64
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.hashes import SHA256
from utils.data_structures import PrivateApiKey, EncryptedFormSubmission


class FormSubmissionDecrypter:

    def decrypt(
        encrypted_submission: EncryptedFormSubmission, private_api_key: PrivateApiKey
    ) -> str:
        try:
            private_key = serialization.load_pem_private_key(
                private_api_key.key.encode(), password=None, backend=default_backend()
            )

            oaep_padding = padding.OAEP(
                mgf=padding.MGF1(algorithm=SHA256()),
                algorithm=SHA256(),
                label=None,
            )

            decrypted_key = private_key.decrypt(
                base64.b64decode(encrypted_submission.encrypted_key),
                oaep_padding,
            )

            decrypted_nonce = private_key.decrypt(
                base64.b64decode(encrypted_submission.encrypted_nonce),
                oaep_padding,
            )

            decrypted_auth_tag = private_key.decrypt(
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
