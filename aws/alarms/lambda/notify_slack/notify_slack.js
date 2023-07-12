var https = require("https");
var util = require("util");
var zlib = require("zlib");

function safeJsonParse(str) {
  try {
    return JSON.parse(str);
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

function getSNSMessageSeverity(message) {
  const errorMessages = ["Error", "Critical"];
  const warningMessages = ["Warning", "FAILURE"];
  var severity = "info";
  var keepProcessing = true;

  for (var errorMessagesItem in errorMessages) {
    if (
      message.indexOf(errorMessages[errorMessagesItem]) != -1 &&
      // Does not inform about OK status
      message.indexOf('"NewStateValue":"OK"') == -1
    ) {
      severity = "error";
      keepProcessing = false;
    } else if (message.indexOf('"NewStateValue":"OK"') != -1) {
      severity = "alarm_reset";
      keepProcessing = false;
    }
  }

  // Don't bother processing if we've already found an error
  if (!keepProcessing) {
    return severity;
  }

  for (var warningMessagesItem in warningMessages) {
    if (
      message.indexOf(warningMessages[warningMessagesItem]) != -1 &&
      // Does not inform about OK status
      message.indexOf('"NewStateValue":"OK"') == -1
    ) {
      severity = "warning";
    } else if (message.indexOf('"NewStateValue":"OK"') != -1) {
      severity = "alarm_reset";
    }
  }

  return severity;
}

function sendToSlack(logGroup, message, severity, context) {
  var environment = process.env.ENVIRONMENT || "Staging";

  const icon_emoji = (severity) => {
    switch (severity) {
      case "danger":
      case "error":
        return ":rotating_light:";
      case "warning":
      case "warn":
        return ":warning:";
      default:
        return ":loudspeaker:";
    }
  };

  var postData = {
    channel: `#forms-${environment.toLowerCase()}-events}`,
    username: "Forms Notifier",
    text: `*${logGroup}*`,
    icon_emoji: icon_emoji(severity),
  };

  postData.attachments = [
    {
      color: severity,
      text: message,
    },
  ];

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
        `Message successfully sent to Slack... severity: ${severity}, message: ${message}`
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
        result = JSON.parse(result.toString());

        const logMessage = safeJsonParse(result.message);
        // If logMessage is false, then the message is not JSON
        if (logMessage) {
          const message = logMessage.msg + logMessage.error ? "/n" + logMessage.error : "";
          sendToSlack(result.logGroup, message, logMessage.level, context);
          console.log(
            JSON.stringify({
              msg: `Event Data for ${result.logGroup}: ${JSON.stringify(logMessage, null, 2)}`,
            })
          );
        } else {
          // These are unhandled errors from the GCForms app only
          sendToSlack(result.logGroup, result.message, "error", context);
          console.log(
            JSON.stringify({
              msg: `Event Data for ${result.logGroup}: ${result.message}`,
            })
          );
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
    sendToSlack("Alarm Event", message, severity, context);
  }
};
