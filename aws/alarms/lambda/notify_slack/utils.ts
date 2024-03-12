import util from "util";
import https from "https";
import { gunzip } from "zlib";
import { URL } from "url";

/**
 * Inspired by https://gist.github.com/ktheory/df3440b01d4b9d3197180d5254d7fb65
 */
export const sendTo = (urlOptions: string | https.RequestOptions | URL, data: any): Promise<any> =>
  new Promise((resolve, reject) => {
    const req = https.request(urlOptions, (res) => {
      const chunks: any[] = [];
      res.setEncoding("utf8");
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("error", reject);
      res.on("end", () => {
        const { statusCode, headers } = res;
        const validResponse: boolean =
          statusCode !== undefined && statusCode >= 200 && statusCode <= 299;
        const body = chunks.join("");

        if (validResponse) resolve({ statusCode, headers, body });
        else reject(new Error(`Request failed. status: ${statusCode}, body: ${body}`));
      });
    });

    req.on("error", reject);
    req.write(util.format("%j", data));
    req.end();
  });

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
  console.log("Sending to Slack...");
  const environment = process.env.ENVIRONMENT || "Staging";
  const logLevelThemeForSlack = logLevelAsEmojiAndColor(logLevel);
  const postData = {
    channel: `#forms-${environment.toLowerCase()}-events`,
    username: "Forms Notifier",
    text: `*${logGroup}*`,
    icon_emoji: logLevelThemeForSlack.emoji,
    attachments: [
      {
        color: logLevelThemeForSlack.color,
        text: logMessage,
      },
    ],
  };

  const options = {
    method: "POST",
    hostname: "hooks.slack.com",
    port: 443,
    path: process.env.SLACK_WEBHOOK,
  };

  try {
    await sendTo(options, postData);
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
  }

  const postData = {
    message: logMessage.length > 130 ? logMessage.substring(0, 126) + "..." : logMessage, // Truncate the message to 130 characters as per OpsGenie's requirements
    entity: `${logGroup}`,
    responders: [{ id: "dbe73fd1-8bfc-4345-bc0a-36987a684d26", type: "team" }], // Forms Team
    priority: "P1",
    description: `Log Message: ${logMessage}`, // This is the full log message
  };

  const options = {
    method: "POST",
    hostname: "api.opsgenie.com",
    port: 443,
    path: "/v2/alerts",
    headers: {
      "Content-Type": "application/json",
      Authorization: `GenieKey ${process.env.OPSGENIE_API_KEY}`,
    },
  };

  console.log("Sending to OpsGenie...");

  try {
    await sendTo(options, postData);
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
      return { emoji: ":rotating_light:", color: "danger" };
    case "warning":
    case "warn":
      return { emoji: ":warning:", color: "warning" };
    default:
      return { emoji: ":loudspeaker:", color: "good" };
  }
}
