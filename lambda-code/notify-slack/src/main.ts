import { sendToSlack, sendToOpsGenie, ungzip } from "./utils.js";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";

const ssmClient = new SSMClient({ region: process.env.REGION ?? "ca-central-1" });

let slackLogFilter: { ignoredLogs: string[]; lastUpdateTimestamp: Date } | undefined = undefined;

export const handler = async (event: any) => {
  console.log("Handling raw event: " + JSON.stringify(event));

  /**
   * Load list of logs that should not be sent to Slack (updated every 3 minutes)
   * Refresh every 3 minutes in case the Lambda is invoked in a warm execution environment
   */
  try {
    if (
      slackLogFilter === undefined ||
      Date.now() - slackLogFilter.lastUpdateTimestamp.getTime() > 3 * 60 * 1000
    ) {
      const commandOutput = await ssmClient.send(
        new GetParameterCommand({
          Name: process.env.IGNORED_LOGS_PARAMETER_STORE_ARN ?? "unknown",
        })
      );

      if (commandOutput.Parameter?.Value !== undefined) {
        slackLogFilter = {
          ignoredLogs: JSON.parse(commandOutput.Parameter.Value),
          lastUpdateTimestamp: new Date(),
        };
      }
    }
  } catch (error) {
    // Leave `slackLogFilter` variable as is

    console.error((error as Error).message);

    await postLogToSlack(
      "/aws/lambda/notify-slack",
      "Failed to load list of logs that should not be sent to Slack",
      "warn"
    );
  }

  try {
    if (event.awslogs) {
      await handleCloudWatchLogEvent(event.awslogs.data);
    } else if (event?.Records?.[0]?.Sns?.Message) {
      await handleSnsEventFromCloudWatchAlarm(event.Records[0].Sns.Message);
    } else {
      console.log("No supported event type found.");
      await postLogToSlack("Unknown Event", JSON.stringify(event, null, 2), "info");
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
  }

  for (const log of parsedResult.logEvents) {
    const logMessage = safeParseLogIncludingJSON(log.message);
    // If logMessage is false, then the message is not JSON
    if (logMessage) {
      const message = `
              ${logMessage.msg}
              ${logMessage.error ? "\n".concat(logMessage.error) : ""}
              ${logMessage.severity ? "\n\nSeverity level: ".concat(logMessage.severity) : ""}
              `;
      await postLogToSlack(parsedResult.logGroup, message, logMessage.level);
      await sendToOpsGenie(parsedResult.logGroup, message, logMessage.severity);
      console.log(
        JSON.stringify({
          msg: `Event Data for ${parsedResult.logGroup}: ${JSON.stringify(logMessage, null, 2)}`,
        })
      );
    } else {
      // Non-JSON log message.  Send as-is and treat as an error.
      await postLogToSlack(parsedResult.logGroup, log.message, "error");

      console.log(
        JSON.stringify({
          msg: `Event Data for ${parsedResult.logGroup}: ${log.message}`,
        })
      );
    }
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

  await postLogToSlack("CloudWatch Alarm Event", message, severity);
  await sendToOpsGenie("CloudWatch Alarm Event", message, severity);
};

function postLogToSlack(logGroup: string, logMessage: string, logLevel: string): Promise<void> {
  if (slackLogFilter !== undefined) {
    const isLogIgnored = slackLogFilter.ignoredLogs.find((message) =>
      logMessage.toLowerCase().includes(message.toLowerCase())
    )
      ? true
      : false;

    if (isLogIgnored) {
      // Not sending to Slack
      return Promise.resolve();
    }
  }

  return sendToSlack(logGroup, logMessage, logLevel);
}
