const encryptionSDK = require("@aws-crypto/client-node");
const {NotifyClient} = require("notifications-node-client");

const KEY_ARN = process.env.KEY_ARN;
const KEY_ALIAS = process.env.KEY_ALIAS;
const TEMPLATE_ID = process.env.TEMPLATE_ID;
const NOTIFY_API_KEY = process.env.NOTIFY_API_KEY;


exports.handler = async (event) => {
  // setup the encryptionSDK's key ring
  const {decrypt} = encryptionSDK.buildDecrypt(encryptionSDK.CommitmentPolicy.FORBID_ENCRYPT_ALLOW_DECRYPT);
  const generatorKeyId = KEY_ALIAS;
  const keyIds = [KEY_ARN];
  const keyring = new encryptionSDK.KmsKeyringNode({generatorKeyId, keyIds});

  // setup the notify client
  const notify = new NotifyClient("https://api.notification.canada.ca", NOTIFY_API_KEY);

  // decrypt the code to plain text if it exists
  let plainTextCode;
  if (event.request.code) {
    try {
      // create Buffer from base64 text
      const codeBuffer = Buffer.from(event.request.code, "base64");
      // decrypt the code into plaintext using the sdk and keyring
      const {plaintext} = await decrypt(keyring, Uint8Array.from(codeBuffer));
      plainTextCode = plaintext;
    } catch (err) {
      console.error(
        `{"status": "failed", "message": "Failed to Decrypt Cognito Code", "error":${JSON.stringify(err)}}`
      );
      throw new Error("Could not decrypt Cognito Code");
    }
  }

  const userEmail = event.request.userAttributes.email;
  if(plainTextCode && userEmail){
    // attempt to send the code to the user through Notify
    try {
      switch (event.triggerSource){
        // https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-custom-email-sender.html#custom-email-sender-lambda-trigger-sources
        case "CustomEmailSender_ForgotPassword":
          await notify.sendEmail(TEMPLATE_ID, userEmail, {
            personalisation: {
              passwordReset: true,
              accountVerification: false,
              resendCode: false,
              code: plainTextCode
            }
          });
          break;
        case "CustomEmailSender_ResendCode":
          await notify.sendEmail(TEMPLATE_ID, userEmail, {
            personalisation: {
              passwordReset: false,
              accountVerification: false,
              resendCode: true,
              code: plainTextCode
            }
          });
          break;
        case "CustomEmailSender_VerifyUserAttribute":
          await notify.sendEmail(TEMPLATE_ID, userEmail, {
            personalisation: {
              passwordReset: false,
              accountVerification: true,
              resendCode: false,
              code: plainTextCode
            }
          });
          break;
      }
    }catch (e){
      console.error(
        `{"status": "failed", "message": "Notify Failed To Send the Code", "error":${JSON.stringify(err)}}`
      );
      throw new Error("Notify failed to send the code")
    }
  }
}