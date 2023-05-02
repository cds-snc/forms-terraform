const { NotifyClient } = require("notifications-node-client");
const crypto = require("crypto");
const aws = require("aws-sdk");
const TEMPLATE_ID = process.env.TEMPLATE_ID;
const NOTIFY_API_KEY = process.env.NOTIFY_API_KEY;

exports.handler = async (event) => {
  let verificationCode = "";
  //Only called once after SRP_A and PASSWORD_VERIFIER challenges. Hence session.length == 2
  if (event.request.session.length === 2) {
    try {
      verificationCode = crypto.randomBytes(3).toString("hex");
      // attempt to send the code to the user through Notify
      // setup the notify client
      const notify = new NotifyClient("https://api.notification.canada.ca", NOTIFY_API_KEY);
      await notify.sendEmail(TEMPLATE_ID, userEmail, {
        personalisation: {
          passwordReset: event.triggerSource === "CustomEmailSender_ForgotPassword",
          accountVerification: event.triggerSource === "CustomEmailSender_SignUp",
          resendCode: event.triggerSource === "CustomEmailSender_ResendCode",
          code: plainTextCode,
        },
      });
    } catch (err) {
      console.error(
        `{"status": "failed", "message": "Notify Failed To Send the Code", "error":${err.message}}`
      );
      throw new Error("Notify failed to send the code");
    }
  } else {
    //if the user makes a mistake, we utilize the verification code from the previous session so that the user can retry.
    const previousChallenge = event.request.session.slice(-1)[0];
    verificationCode = previousChallenge.challengeMetadata;
  }

  //add to privateChallengeParameters. This will be used by verify auth lambda.
  console.log(verificationCode);
  event.response.privateChallengeParameters = {
    verificationCode: verificationCode,
  };

  //add it to session, so its available during the next invocation.
  event.response.challengeMetadata = verificationCode;

  return event;
};
