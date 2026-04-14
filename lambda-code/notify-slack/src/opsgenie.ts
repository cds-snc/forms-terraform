import axios from "axios";

export const Priority = {
  p1: "P1",
  p2: "P2",
} as const;

export type Priority = (typeof Priority)[keyof typeof Priority];

export async function sendToOpsGenie(
  entity: string,
  message: string,
  priority: Priority
): Promise<void> {
  try {
    await axios.post(
      "https://api.opsgenie.com/v2/alerts",
      {
        message: message.length > 130 ? message.substring(0, 126) + "..." : message, // OpsGenie limit is 130 characters
        description: `Log message: ${message}`, // OpsGenie limit is 15000 characters
        entity, // OpsGenie limit is 512 characters
        priority, // OpsGenie only accept following values P1, P2, P3, P4 and P5.
      },
      { headers: { Authorization: `GenieKey ${process.env.OPSGENIE_API_KEY}` } }
    );
  } catch (error) {
    console.error(`OpsGenie API call failed. Reason ${(error as Error).message}`);

    throw error;
  }
}
