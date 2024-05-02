import encryptionSDK from "@aws-crypto/client-node";
import { Handler } from "aws-lambda";
import { NotifyClient } from "notifications-node-client";
import { AxiosError } from "axios";
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

const KEY_ARN = process.env.KEY_ARN;
const KEY_ALIAS = process.env.KEY_ALIAS;
const TEMPLATE_ID = process.env.TEMPLATE_ID;

if (!KEY_ARN || !KEY_ALIAS || !TEMPLATE_ID) {
  throw new Error(
    `Missing Environment Variables: ${KEY_ARN ? "" : "Key ARN"} ${KEY_ALIAS ? "" : "Key Alias"} ${
      TEMPLATE_ID ? "" : "Template ID"
    }`
  );
}

const client = new SecretsManagerClient();
const command = new GetSecretValueCommand({ SecretId: process.env.NOTIFY_API_KEY });
console.log("Retrieving Notify API Key from Secrets Manager");
const notifyApiKey = await client.send(command);
const notifyClient = new NotifyClient(
  "https://api.notification.canada.ca",
  notifyApiKey.SecretString
);

export const handler: Handler = async (event) => {
  // setup the encryptionSDK's key ring
  const { decrypt } = encryptionSDK.buildDecrypt(
    encryptionSDK.CommitmentPolicy.FORBID_ENCRYPT_ALLOW_DECRYPT
  );
  const generatorKeyId = KEY_ALIAS;
  const keyIds = [KEY_ARN];
  const keyring = new encryptionSDK.KmsKeyringNode({ generatorKeyId, keyIds });

  // decrypt the code to plain text if it exists
  let plainTextCode;
  if (event.request.code) {
    try {
      // create Buffer from base64 text
      const codeBuffer = Buffer.from(event.request.code, "base64");
      // decrypt the code into plaintext using the sdk and keyring
      const { plaintext } = await decrypt(keyring, Uint8Array.from(codeBuffer));
      plainTextCode = plaintext.toString();
    } catch (err) {
      console.error(
        JSON.stringify({
          status: "failed",
          message: "Failed to Decrypt Cognito Code.",
          error: (err as Error).message,
        })
      );
      throw new Error("Could not decrypt Cognito Code");
    }
  }

  const userEmail = event.request.userAttributes.email;
  if (
    plainTextCode &&
    userEmail &&
    ["CustomEmailSender_ForgotPassword"].includes(event.triggerSource)
  ) {
    // attempt to send the code to the user through Notify
    try {
      await notifyClient.sendEmail(TEMPLATE_ID, userEmail, {
        personalisation: {
          passwordReset: event.triggerSource === "CustomEmailSender_ForgotPassword",
          // Keeping `accountVerification` and `resendCode` variables in case we need them in the future. They were removed when we implemented 2FA.
          accountVerification: false,
          resendCode: false,
          code: plainTextCode,
        },
      });
    } catch (err) {
      if (err instanceof AxiosError) {
        // Error Message will be sent to slack
        console.error(
          JSON.stringify({
            level: "error",
            msg: `Failed to send password reset email to ${userEmail}`,
            error: err.response?.data?.errors
              ? JSON.stringify(err.response.data.errors)
              : err.message,
          })
        );
      } else {
        console.error(
          JSON.stringify({
            status: "failed",
            message: `Failed to send password reset email to ${userEmail}`,
            error: (err as Error).message,
          })
        );
      }
      throw new Error("Notify failed to send the code");
    }
  }
};
