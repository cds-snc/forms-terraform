import util from "util";
import https from "https";

export const sendToSlack = (logGroup: string, logMessage: string, logLevel: string) => {
  var environment = process.env.ENVIRONMENT || "Staging";

  const logLevelAsEmojiAndColor = (emojiLevel: string) => {
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
  };

  const logLevelThemeForSlack = logLevelAsEmojiAndColor(logLevel);

  var postData = {
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

  var options = {
    method: "POST",
    hostname: "hooks.slack.com",
    port: 443,
    path: process.env.SLACK_WEBHOOK,
  };

  var req = https.request(options, function (res) {
    res.setEncoding("utf8");
    res.on("data", function () {
      console.log(
        JSON.stringify({
          msg: `Message successfully sent to Slack... log level: ${logLevel}, log message: ${logMessage}`,
        })
      );
    });
  });

  req.on("error", function (e) {
    console.log(
      JSON.stringify({
        msg: `problem with request: ${e.message}`,
      })
    );
  });

  req.write(util.format("%j", postData));
  req.end();

  return true;
};

export const sendToOpsGenie = (logGroup: string, logMessage: string, logSeverity: string) => {
  if (logSeverity != "1" && logSeverity !== "SEV1") {
    console.log(
      `Skipping sending to OpsGenie because logSeverity is not SEV1 or 1: ${logSeverity}`
    );
    return false;
  }

  var postData = {
    message: logMessage.length > 130 ? logMessage.substring(0, 126) + "..." : logMessage, // Truncate the message to 130 characters as per OpsGenie's requirements
    entity: `${logGroup}`,
    responders: [{ id: "dbe73fd1-8bfc-4345-bc0a-36987a684d26", type: "team" }], // Forms Team
    priority: "P1",
    description: `Log Message: ${logMessage}`, // This is the full log message
  };

  var options = {
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

  var req = https.request(options, function (res) {
    res.setEncoding("utf8");
    res.on("data", function () {
      console.log(
        JSON.stringify({
          msg: `Message successfully sent to OpsGenie with log message: ${logMessage}`,
        })
      );
    });
  });

  req.on("error", function (e) {
    console.log(
      JSON.stringify({
        msg: `problem with request: ${e.message}`,
      })
    );
  });

  req.write(util.format("%j", postData));
  req.end();

  return true;
};
