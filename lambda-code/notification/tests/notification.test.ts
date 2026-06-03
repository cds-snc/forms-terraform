import { describe, it, expect, vi, afterEach } from "vitest";
import { SQSEvent } from "aws-lambda";
import { Notification } from "../src/lib/types.js";

// These modules need to be mocked before importing
vi.mock("../src/lib/email.js", () => ({
  notifyByEmail: vi.fn(),
}));

vi.mock("../src/lib/db.js", () => ({
  retrieveNotification: vi.fn(),
}));

import * as main from "../src/main.js";
import * as db from "../src/lib/db.js";
import * as email from "../src/lib/email.js";

describe("Notification Lambda Handler SQS batch processing", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  describe("handler", () => {
    it("should return empty batchItemFailures when all messages succeed", async () => {
      const notification: Notification = {
        id: "notificationId-1",
        emailRecipients: ["test@cds-snc.ca"],
        emailSubject: "Test Subject",
        emailBody: "Test Body",
      };

      vi.mocked(db.retrieveNotification).mockResolvedValueOnce(notification);

      vi.mocked(email.notifyByEmail).mockResolvedValueOnce();

      const event: SQSEvent = {
        Records: [
          {
            messageId: "sqs-messsage-1",
            body: JSON.stringify({ notificationId: "notificationId-1" }),
            // Using a full object since testing a valild event
            receiptHandle: "receipt-1",
            attributes: {} as any,
            messageAttributes: {},
            md5OfBody: "md5",
            eventSource: "aws:sqs",
            eventSourceARN: "arn:aws:sqs:region:account:queue",
            awsRegion: "ca-central-1",
          },
        ],
      };

      const result = await main.handler(event, {} as any, {} as any);

      expect(result.batchItemFailures).toHaveLength(0);
      expect(db.retrieveNotification).toHaveBeenCalledWith("notificationId-1");
      expect(email.notifyByEmail).toHaveBeenCalledWith(notification);
    });

    // Common case of code queuing a notification but the record may not exist e.g. reliability lambda
    it("should fail processing notification when record not found", async () => {
      // Simulate notification not found in DB
      vi.mocked(db.retrieveNotification).mockResolvedValueOnce(undefined);

      const event: SQSEvent = {
        Records: [
          {
            messageId: "sqs-messsage-1",
            body: JSON.stringify({ notificationId: "missing-123" }),
          } as any,
        ],
      };
      const result = await main.handler(event, {} as any, {} as any);

      expect(result.batchItemFailures).toHaveLength(1);
    });

    it("should handle partial batch failures correctly", async () => {
      const consoleErrorSpy = vi.spyOn(console, "error");

      vi.mocked(db.retrieveNotification).mockImplementation(async (notificationId: string) => {
        switch (notificationId) {
          case "notificationId-1":
          case "notificationId-2":
          case "notificationId-3":
            return {
              id: notificationId,
              emailRecipients: ["test@cds-snc.ca"],
              emailSubject: "Test Subject",
              emailBody: "Test Body",
            };
          default:
            return undefined;
        }
      });

      vi.mocked(email.notifyByEmail).mockImplementation(async (notification: Notification) => {
        if (notification.id === "notificationId-2") throw new Error("Email service error");
      });

      const event: SQSEvent = {
        Records: [
          {
            messageId: "sqs-messsage-1",
            body: JSON.stringify({ notificationId: "notificationId-1" }),
          } as any,
          {
            messageId: "sqs-messsage-2",
            body: JSON.stringify({ notificationId: "notificationId-2" }),
          } as any,
          {
            messageId: "sqs-messsage-3",
            body: JSON.stringify({ notificationId: "notificationId-3" }),
          } as any,
          {
            messageId: "sqs-messsage-4",
            body: JSON.stringify({ notificationId: "notificationId-4" }),
          } as any,
        ],
      };

      const result = await main.handler(event, {} as any, {} as any);

      expect(result.batchItemFailures).toHaveLength(2);
      expect(result.batchItemFailures).toEqual([
        { itemIdentifier: "sqs-messsage-2" },
        { itemIdentifier: "sqs-messsage-4" },
      ]);
      expect(email.notifyByEmail).toHaveBeenCalledTimes(3); // Only called for messages 1, 2, 3 (not 4)
      const loggedMessages = consoleErrorSpy.mock.calls.map(([message]) => message);
      expect(loggedMessages).toEqual(
        expect.arrayContaining([
          expect.stringContaining(
            '{"level":"error","msg":"Failed to handle notification notificationId-2","error":"Email service error"}'
          ),
          expect.stringContaining(
            '{"level":"error","msg":"Failed to handle notification notificationId-4","error":"Could not find notification in database"}'
          ),
        ])
      );
    });
  });
});
