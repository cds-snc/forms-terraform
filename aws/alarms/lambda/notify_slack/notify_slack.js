import { Context, Handler } from "aws-lambda";
import https from "https";
import util from "util";
import zlib from "zlib";

/**
 * Some log contains metadata information like `2023-07-13T13:48:30.151Z  535741e0-25a9-4c8b-a0a1-25d2b24bf1b4  INFO`
 * which we want to ignore.
 *
 * @returns JSON object or false if the message is not JSON
 */
export const safeParseLogIncludingJSON = (message: string) => {
  try {
    const jsonPartOfLogMessage = message.slice(message.indexOf("{"));
    return JSON.parse(jsonPartOfLogMessage);
  } catch (e) {
    return false;
  }
};

export const getAlarmDescription = (message: string) => {
  try {
    const parsedMessage = JSON.parse(message);
    return parsedMessage.AlarmDescription ? parsedMessage.AlarmDescription : parsedMessage;
  } catch (err) {
    return message;
  }
};

/**
 * @returns the severity level: [error, warning, info, alarm_reset] based on the message
 */
export const getSNSMessageSeverity = (message: string) => {
  const errorMessages = ["error", "critical"];
  const warningMessages = ["warning", "failure"];
  const alarm_ok_status = '"newstatevalue":"ok"'; // This is the string that is returned when the alarm is reset

  message = message.toLowerCase();

  if (message.indexOf("sev1") != -1) return "SEV1";

  for (var errorMessagesItem in errorMessages) {
    if (
      message.indexOf(errorMessages[errorMessagesItem]) != -1 &&
      message.indexOf(alarm_ok_status) == -1 // is not an OK status
    ) {
      return "error";
    } else if (message.indexOf(alarm_ok_status) != -1) {
      return "alarm_reset";
    }
  }

  for (var warningMessagesItem in warningMessages) {
    if (
      message.indexOf(warningMessages[warningMessagesItem]) != -1 &&
      message.indexOf(alarm_ok_status) == -1 // is not an OK status
    ) {
      return "warning";
    } else if (message.indexOf(alarm_ok_status) != -1) {
      return "alarm_reset";
    }
  }

  return "info";
};

export const sendToOpsGenie = (logGroup: string, logMessage: string, logSeverity: string) => {
  if (logSeverity !== "1" && logSeverity !== "SEV1") {
    console.log(`Skipping sending to OpsGenie because logSeverity is not SEV1: ${logSeverity}`);
    return; // skip sending to OpsGenie
  }

  var postData = {
    message: logMessage.substring(0, 130) + "...", // Truncate the message to 130 characters as per OpsGenie's requirements
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
};

export const sendToSlack = (
  logGroup: string,
  logMessage: string,
  logLevel: string,
  context: any
) => {
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
      context.succeed(
        `Message successfully sent to Slack... log level: ${logLevel}, log message: ${logMessage}`
      );
    });
  });

  req.on("error", function (e) {
    console.log(
      JSON.stringify({
        msg: `problem with request: ${e.message}`,
      })
    );
    context.fail(e);
  });

  req.write(util.format("%j", postData));
  req.end();
};

export const handler: Handler = async (event: any, context: Context) => {
  if (event.awslogs) {
    // This is a CloudWatch log event
    var payload = Buffer.from(event.awslogs.data, "base64");
    zlib.gunzip(payload, function (e, result) {
      if (e) {
        context.fail(e);
      } else {
        const parsedResult = JSON.parse(result.toString());

        // We can get events with a `CONTROL_MESSAGE` type. It happens when CloudWatch checks if the Lambda is reachable.
        if (parsedResult.messageType !== "DATA_MESSAGE") return;

        for (const log of parsedResult.logEvents) {
          const logMessage = safeParseLogIncludingJSON(log.message);
          // If logMessage is false, then the message is not JSON
          if (logMessage) {
            const message = `
            ${logMessage.msg}
            ${logMessage.error ? "\n".concat(logMessage.error) : ""}
            ${logMessage.severity ? "\n\nSeverity level: ".concat(logMessage.severity) : ""}
            `;
            sendToSlack(parsedResult.logGroup, message, logMessage.level, context);
            sendToOpsGenie(parsedResult.logGroup, message, logMessage.severity);
            console.log(
              JSON.stringify({
                msg: `Event Data for ${parsedResult.logGroup}: ${JSON.stringify(
                  logMessage,
                  null,
                  2
                )}`,
              })
            );
          } else {
            // These are unhandled errors from the GCForms app only
            sendToSlack(parsedResult.logGroup, log.message, "error", context);

            console.log(
              JSON.stringify({
                msg: `Event Data for ${parsedResult.logGroup}: ${log.message}`,
              })
            );
          }
        }
      }
    });
  } else {
    // This is an SNS message triggered by an AWS CloudWatch alarm
    var message = event.Records[0].Sns.Message;

    const severity = getSNSMessageSeverity(message);

    if (severity === "alarm_reset") {
      message = "Alarm Status now OK - " + getAlarmDescription(message);
    } else {
      message = getAlarmDescription(message);
    }

    console.log(
      JSON.stringify({
        msg: `Event Data for Alarms: ${event.Records[0].Sns.Message}`,
      })
    );

    sendToSlack("CloudWatch Alarm Event", message, severity, context);
    sendToOpsGenie("CloudWatch Alarm Event", message, severity);
  }
};