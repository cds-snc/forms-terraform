import { Priority, sendToOpsGenie } from "./opsgenie.js";
import { sendToSlack } from "./slack.js";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";

export type LogEvent = {
  group: string;
  message: string;
  level: string; // Once we rework the log structure we should combine level and security into one specific log property that reflects on the importance of said log
  severity: string; // Right now severity only appears to be used for the kind of log/alarm that could be sent to OpsGenie
};

const SeverityLevel = {
  sev1: "sev1",
  sev2: "sev2",
  other: "other",
} as const;

type SeverityLevel = (typeof SeverityLevel)[keyof typeof SeverityLevel];

const ssmClient = new SSMClient({ region: process.env.REGION ?? "ca-central-1" });

let slackLogFilter: { ignoredLogs: string[]; lastUpdateTimestamp: Date } | undefined = undefined;

export async function notifyGcFormsTeam(logEvent: LogEvent): Promise<void> {
  // Allow both notification paths to complete to prevent one from interrupting the other
  const notificationOperationResults = await Promise.allSettled([
    notifyDevelopmentTeamThroughSlack(logEvent),
    notifyOnCallTeamThroughOpsGenie(logEvent),
  ]);

  if (notificationOperationResults.find((r) => r.status === "rejected")) {
    throw new Error("Failed to send one or both notifications (Slack and/or OpsGenie");
  }
}

async function notifyDevelopmentTeamThroughSlack(logEvent: LogEvent): Promise<void> {
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
    await sendToSlack(
      "/aws/lambda/notify-slack",
      `Failed to load list of logs that should not be sent to Slack. Reason ${(error as Error).message}`,
      "warn"
    );

    // Leave `slackLogFilter` variable as is
  }

  try {
    if (slackLogFilter !== undefined) {
      const isLogIgnored = slackLogFilter.ignoredLogs.find((message) =>
        logEvent.message.toLowerCase().includes(message.toLowerCase())
      )
        ? true
        : false;

      if (isLogIgnored) {
        // Not sending to Slack
        return Promise.resolve();
      }
    }

    await sendToSlack(logEvent.group, logEvent.message, logEvent.level);
  } catch (error) {
    console.error(
      `Failed to notify development team through Slack. Reason ${(error as Error).message}`
    );

    throw error;
  }
}

async function notifyOnCallTeamThroughOpsGenie(logEvent: LogEvent): Promise<void> {
  // OpsGenie is only enabled in Production
  if (process.env.ENVIRONMENT !== "production") {
    return Promise.resolve();
  }

  try {
    const detectedSeverityLevel = detectSeverityLevel(logEvent.severity);

    switch (detectedSeverityLevel) {
      case SeverityLevel.sev1:
        await sendToOpsGenie(logEvent.group, logEvent.message, Priority.p1);
        break;
      case SeverityLevel.sev2:
        if (isWithinBusinessHours()) {
          await sendToOpsGenie(logEvent.group, logEvent.message, Priority.p2);
        }
        break;
      default:
        break;
    }
  } catch (error) {
    console.error(
      `Failed to notify On Call team through OpsGenie. Reason ${(error as Error).message}`
    );

    throw error;
  }
}

function detectSeverityLevel(severity: string): SeverityLevel {
  switch (severity) {
    case "1":
    case "SEV1":
      return SeverityLevel.sev1;
    case "2":
    case "SEV2":
      return SeverityLevel.sev2;
    default:
      return SeverityLevel.other;
  }
}

function isWithinBusinessHours(): boolean {
  try {
    const currentDate = new Date();

    const dateFormatter = new Intl.DateTimeFormat("en-US", {
      timeZone: "America/New_York",
      weekday: "short",
      hour: "numeric",
      hour12: false,
    });

    const dateParts = dateFormatter.formatToParts(currentDate);

    const weekday = dateParts.find((p) => p.type === "weekday")?.value;
    const hour = Number(dateParts.find((p) => p.type === "hour")?.value);

    const isWeekday = ["Mon", "Tue", "Wed", "Thu", "Fri"].includes(weekday!); // Monday to Friday
    const isWithinHours = hour >= 8 && hour < 16; // Between 8 AM and 4 PM

    return isWeekday && isWithinHours;
  } catch (error) {
    // If something goes wrong we will rely on Slack notification
    return false;
  }
}
