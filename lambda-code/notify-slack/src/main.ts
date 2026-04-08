import { Handler } from "aws-lambda";
import { gunzip } from "zlib";
import { notifyGcFormsTeam } from "./notificationRouter.js";

export const handler: Handler = async (event: any) => {
  try {
    console.log("Handling raw event: " + JSON.stringify(event));

    if (event.awslogs) {
      await handleCloudWatchLogEvent(event.awslogs.data);
    } else if (event?.Records?.[0]?.Sns?.Message) {
      await handleSnsEventFromCloudWatchAlarm(event.Records[0].Sns.Message);
    } else {
      await notifyGcFormsTeam({
        group: "Unknown Event",
        message: JSON.stringify(event, null, 2),
        level: "warn",
        severity: "", // Not applicable here. Will disappear once we rework the `notify-slack` Lambda function
      });
    }
  } catch (error) {
    await notifyGcFormsTeam({
      group: "/aws/lambda/notify-slack",
      message: `Failed to run Notify Slack. Reason: ${(error as Error).message}`,
      level: "error",
      severity: "SEV2",
    });

    throw error;
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
    const jsonParsed = JSON.parse(jsonPartOfLogMessage);
    return jsonParsed && typeof jsonParsed === "object" ? jsonParsed : false;
  } catch (e) {
    return false;
  }
};

const getAlarmDescription = (message: string): string => {
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
  const warningMessages = ["warning", "failure", "failed"];
  const alarm_ok_status = '"newstatevalue":"ok"'; // This is the string that is returned when the alarm is reset

  message = message.toLowerCase();

  if (message.indexOf("sev1") != -1) return "SEV1";
  if (message.indexOf("sev2") != -1) return "SEV2";

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

const handleCloudWatchLogEvent = async (logData: string) => {
  console.log("Received CloudWatch logs event: ", JSON.stringify(logData));
  const payload = Buffer.from(logData, "base64");

  let decompressed: string = "";
  try {
    decompressed = (await ungzip(payload)) as string;
  } catch (error) {
    console.log("Error decompressing payload: ", error);
    throw error;
  }
  const parsedResult = JSON.parse(decompressed);
  // We can get events with a `CONTROL_MESSAGE` type. It happens when CloudWatch checks if the Lambda is reachable.
  if (parsedResult.messageType !== "DATA_MESSAGE") {
    console.log("Received a non-data message: exiting.. ");
    return Promise.resolve();
  }

  let didOneNotificationFailedToBeSent = false;

  for (const log of parsedResult.logEvents) {
    const logMessage = safeParseLogIncludingJSON(log.message);

    // If logMessage is false, then the message is not JSON
    if (logMessage) {
      const message = `
              ${logMessage.msg}
              ${logMessage.error ? "\n".concat(logMessage.error) : ""}
              ${logMessage.severity ? "\n\nSeverity level: ".concat(logMessage.severity) : ""}
              `;

      console.log(
        JSON.stringify({
          msg: `Event Data for ${parsedResult.logGroup}: ${JSON.stringify(logMessage, null, 2)}`,
        })
      );

      await notifyGcFormsTeam({
        group: parsedResult.logGroup,
        message,
        level: logMessage.level ?? "",
        severity: logMessage.severity ?? "",
      }).catch(() => {
        didOneNotificationFailedToBeSent = true; // Flag failure but continue processing other logs in case there is a transient network error
      });
    } else {
      console.log(
        JSON.stringify({
          msg: `Event Data for ${parsedResult.logGroup}: ${log.message}`,
        })
      );

      // Non-JSON log message. Send as-is and treat as an error.
      await notifyGcFormsTeam({
        group: parsedResult.logGroup,
        message: log.message,
        level: "error",
        severity: "", // Not applicable here. Will disappear once we rework the `notify-slack` Lambda function
      }).catch(() => {
        didOneNotificationFailedToBeSent = true; // Flag failure but continue processing other logs in case there is a transient network error
      });
    }
  }

  if (didOneNotificationFailedToBeSent) {
    throw new Error("At least one log event notification failed to reach the GC Forms team");
  }
};

const handleSnsEventFromCloudWatchAlarm = async (message: string) => {
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

  await notifyGcFormsTeam({
    group: "CloudWatch Alarm Event",
    message,
    level: severity, // Assigning severity to level here will allow for the right Slack Emoji to be selected when a message is posted
    severity,
  });
};

const ungzip = (input: Buffer) => {
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
