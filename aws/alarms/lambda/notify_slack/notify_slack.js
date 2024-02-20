var https = require("https");
var util = require("util");
var zlib = require("zlib");

function safeParseLogIncludingJSON(message) {
  try {
    // When we get a log it contains more than just the message we want. It also contains information like `2023-07-13T13:48:30.151Z	535741e0-25a9-4c8b-a0a1-25d2b24bf1b4	INFO`.
    const jsonPartOfLogMessage = message.slice(message.indexOf('{'));
    return JSON.parse(jsonPartOfLogMessage);
  } catch (e) {
    return false;
  }
}

function getMessage(message) {
  try {
    const parsedMessage = JSON.parse(message);
    return parsedMessage.AlarmDescription ? parsedMessage.AlarmDescription : parsedMessage;
  } catch (err) {
    return message;
  }
}

/**
 * @returns the severity level: [error, warning, info, alarm_reset] based on the message
 */
function getSNSMessageSeverity(message) {
  const errorMessages = ["error", "critical"];
  const warningMessages = ["warning", "failure"];
  const alarm_ok_status = '"NewStateValue":"OK"'; // This is the string that is returned when the alarm is reset

  message = message.toLowerCase();
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
}

function sendToOpsGenie(logGroup, logMessage, logLevel, context) {

  const weShouldPageOnCall = (logLevel) => {
    switch (logLevel) {
      case "danger":
      case "critical":
      case "error":
        return true;
      default:
        return false;
    }
  };

  if (!weShouldPageOnCall(logLevel)) {
    return; // skip sending to OpsGenie
  }

  var postData = {
    message: logMessage,
    entity: `*${logGroup}*`,
    priority: "P1",
  };

  var options = {
    method: "POST",
    hostname: "api.opsgenie.com",
    port: 443,
    path: "/v2/alerts",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `GenieKey ${process.env.OPSGENIE_API_KEY}`,
    },
  };

  var req = https.request(options, function (res) {
    res.setEncoding("utf8");
    res.on("data", function () {
      console.log(
        JSON.stringify({
          msg: `Message successfully sent to OpsGenie... log level: ${logLevel}, log message: ${logMessage}`,
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

}

function sendToSlack(logGroup, logMessage, logLevel, context) {
  var environment = process.env.ENVIRONMENT || "Staging";

  const logLevelAsEmojiAndColor = (logLevel) => {
    switch (logLevel) {
      case "danger":
      case "error":
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
  };

  postData.attachments = [{
    color: logLevelThemeForSlack.color,
    text: logMessage,
  }];

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
}

exports.handler = function (input, context) {
  if (input.awslogs) {
    // This is a CloudWatch log event
    var payload = Buffer.from(input.awslogs.data, "base64");
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
            sendToOpsGenie(parsedResult.logGroup, message, logMessage.level, context);
            console.log(
              JSON.stringify({
                msg: `Event Data for ${parsedResult.logGroup}: ${JSON.stringify(logMessage, null, 2)}`,
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
    var message = input.Records[0].Sns.Message;

    const severity = getSNSMessageSeverity(message);

    if (severity === "alarm_reset") {
      message = "Alarm Status now OK - " + getMessage(message);
    }

    console.log(
      JSON.stringify({
        msg: `Event Data for Alarms: ${input.Records[0].Sns.Message}`,
      })
    );

    sendToSlack("CloudWatch Alarm Event", message, severity, context);
    sendToOpsGenie("CloudWatch Alarm Event", message, severity, context);
  }
};