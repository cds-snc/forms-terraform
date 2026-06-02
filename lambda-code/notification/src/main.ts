import { Handler, SQSEvent } from "aws-lambda";
import { notifyByEmail } from "@lib/email.js";
import { retrieveNotification } from "@lib/db.js";

type OperationResult = { status: "success" } | { status: "failure"; id: string };

export const handler: Handler = async (event: SQSEvent) => {
  const operations: Promise<OperationResult>[] = event.Records.map((event) => {
    const { notificationId }: { notificationId: string } = JSON.parse(event.body);
    return handleNotification(notificationId)
      .then(
        (): OperationResult => ({
          status: "success",
        })
      )
      .catch(() => ({ status: "failure", id: event.messageId }));
  });

  const operationResults = await Promise.all(operations);

  const batchItemFailures = operationResults
    .filter((r): r is Extract<OperationResult, { status: "failure" }> => r.status === "failure")
    .map((r) => ({
      itemIdentifier: r.id,
    }));

  return { batchItemFailures };
};

async function handleNotification(notificationId: string): Promise<void> {
  try {
    const notification = await retrieveNotification(notificationId);

    if (notification === undefined) {
      throw new Error(`Could not find notification in database`);
    }

    await notifyByEmail(notification);
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        msg: `Failed to handle notification ${notificationId}`,
        error: (error as Error).message,
      })
    );

    throw error;
  }
}
