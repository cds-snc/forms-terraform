import { gunzip } from "zlib";
import { sendToSlack, sendToOpsGenie } from "./utils.js";

export const handler = async (event: any) => {
  console.log(JSON.stringify(event));
  try {
    if (event.awslogs) {
      await handleCloudWatchLogEvent(event.awslogs.data);
    } else if (event?.Records?.[0]?.Sns?.Message) {
      handleSnsEventFromCloudWatchAlarm(event.Records[0].Sns.Message);
    } else {
      console.log("No supported event type found.");
      sendToSlack("Unknown Event", JSON.stringify(event, null, 2), "info");
    }

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    console.log("Handler Error: ", error);
    return {
      statusCode: "ERROR",
      error: (error as Error).message,
    };
  }
};

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

export const getAlarmDescription = (message: string): string => {
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
export const getSNSMessageSeverity = (message: string): string => {
  const errorMessages = ["error", "critical"];
  const warningMessages = ["warning", "failure"];
  const alarm_ok_status = '"newstatevalue":"ok"'; // This is the string that is returned when the alarm is reset

  message = message.toLowerCase();

  if (message.indexOf("sev1") != -1) return "SEV1";

  for (const errorMessagesItem in errorMessages) {
    if (
      message.indexOf(errorMessages[errorMessagesItem]) != -1 &&
      message.indexOf(alarm_ok_status) == -1 // is not an OK status
    ) {
      return "error";
    } else if (message.indexOf(alarm_ok_status) != -1) {
      return "alarm_reset";
    }
  }

  for (const warningMessagesItem in warningMessages) {
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

export const handleCloudWatchLogEvent = async (logData: string) => {
  console.log("Received CloudWatch logs event: ", JSON.stringify(logData));
  const payload = Buffer.from(logData, "base64");

  return new Promise<void>(function (resolve, reject) {
    gunzip(payload, function (error, result) {
      if (error) {
        reject(error);
      } else {
        const parsedResult = JSON.parse(result.toString());

        // We can get events with a `CONTROL_MESSAGE` type. It happens when CloudWatch checks if the Lambda is reachable.
        if (parsedResult.messageType !== "DATA_MESSAGE") resolve();

        for (const log of parsedResult.logEvents) {
          const logMessage = safeParseLogIncludingJSON(log.message);
          // If logMessage is false, then the message is not JSON
          if (logMessage) {
            const message = `
              ${logMessage.msg}
              ${logMessage.error ? "\n".concat(logMessage.error) : ""}
              ${logMessage.severity ? "\n\nSeverity level: ".concat(logMessage.severity) : ""}
              `;
            sendToSlack(parsedResult.logGroup, message, logMessage.level);
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
            sendToSlack(parsedResult.logGroup, log.message, "error");

            console.log(
              JSON.stringify({
                msg: `Event Data for ${parsedResult.logGroup}: ${log.message}`,
              })
            );
          }
        }
        resolve();
      }
    });
  });
};

export const handleSnsEventFromCloudWatchAlarm = (message: string) => {
  console.log(
    JSON.stringify({
      msg: `Event Data for Alarms: ${message}`,
    })
  );

  const severity = getSNSMessageSeverity(message);

  if (severity === "alarm_reset") {
    message = "Alarm Status now OK - " + getAlarmDescription(message);
  } else {
    message = getAlarmDescription(message);
  }

  sendToSlack("CloudWatch Alarm Event", message, severity);
  sendToOpsGenie("CloudWatch Alarm Event", message, severity);
};
