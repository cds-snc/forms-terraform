import { gunzip } from "zlib";
import axios from "axios";

export const ungzip = (input: Buffer) => {
  return new Promise((resolve, reject) => {
    gunzip(input, (err: any, result: any) => {
      if (err) {
        reject(err);
      } else {
        resolve(result.toString());
      }
    });
  });
};

export const sendToSlack = async (logGroup: string, logMessage: string, logLevel: string) => {
  const logLevelThemeForSlack = logLevelAsEmojiAndColor(logLevel);

  try {
    if (process.env.SLACK_WEBHOOK === undefined) {
      await sendToOpsGenie(
        "/aws/lambda/NotifySlack",
        "SLACK_WEBHOOK is undefined in the notify-slack Lambda function",
        "SEV1"
      );

      throw new Error("SLACK_WEBHOOK is undefined");
    }

    await axios.post(process.env.SLACK_WEBHOOK, {
      attachments: [
        {
          color: logLevelThemeForSlack.color,
          blocks: [
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: `${logLevelThemeForSlack.emoji} *${logGroup}*`,
              },
            },
            {
              type: "divider",
            },
            {
              type: "section",
              text: {
                type: "plain_text",
                text: logMessage,
              },
            },
          ],
        },
      ],
    });

    console.log(
      `Message successfully sent to Slack... log level: ${logLevel}, log message: ${logMessage}`
    );
  } catch (error) {
    console.log("Error sending to Slack: ", error);
    throw error;
  }
};

export const sendToOpsGenie = async (logGroup: string, logMessage: string, logSeverity: string) => {
  if (logSeverity != "1" && logSeverity !== "SEV1") {
    console.log(
      `Skipping sending to OpsGenie because logSeverity is not SEV1 or 1: ${logSeverity}`
    );
    return;
  }

  const environment = process.env.ENVIRONMENT || "staging";

  if (environment !== "production") {
    console.log(
      `Skipping sending to OpsGenie because environment is not production: ${environment}`
    );
    return;
  }

  try {
    await axios.post(
      "https://api.opsgenie.com/v2/alerts",
      {
        message: logMessage.length > 130 ? logMessage.substring(0, 126) + "..." : logMessage, // Truncate the message to 130 characters as per OpsGenie's requirements
        entity: `${logGroup}`,
        responders: [{ id: "dbe73fd1-8bfc-4345-bc0a-36987a684d26", type: "team" }], // Forms Team
        priority: "P1",
        description: `Log Message: ${logMessage}`, // This is the full log message
      },
      { headers: { Authorization: `GenieKey ${process.env.OPSGENIE_API_KEY}` } }
    );

    console.log(`Message successfully sent to OpsGenie... log message: ${logMessage}`);
  } catch (error) {
    console.log("Error sending to OpsGenie: ", error);
    throw error;
  }
};

function logLevelAsEmojiAndColor(emojiLevel: string): { emoji: string; color: string } {
  switch (emojiLevel) {
    case "danger":
    case "error":
    case "SEV1":
      return { emoji: ":rotating_light:", color: "#eb1607" };
    case "warning":
    case "warn":
      return { emoji: ":warning:", color: "#f29c3a" };
    default:
      return { emoji: ":loudspeaker:", color: "#0ac73f" };
  }
}
