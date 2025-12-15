import { describe, it, expect, vi, afterEach } from "vitest";
import { SQSEvent } from "aws-lambda";

// These modules need to be mocked before importing
vi.mock("../src/lib/email.js", () => ({
  sendNotification: vi.fn(),
}));

vi.mock("../src/lib/db.js", () => ({
  consumeNotification: vi.fn(),
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
      vi.mocked(db.consumeNotification).mockResolvedValue({
        NotificationID: "notificationId-1",
        Emails: ["test@cds-snc.ca"],
        Subject: "Test Subject",
        Body: "Test Body",
      });

      vi.mocked(email.sendNotification).mockResolvedValue();

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
      expect(db.consumeNotification).toHaveBeenCalledWith("notificationId-1");
      expect(email.sendNotification).toHaveBeenCalledWith(
        "notificationId-1",
        ["test@cds-snc.ca"],
        "Test Subject",
        "Test Body"
      );
    });

    // Common case of code queuing a notification but the record may not exist e.g. reliability lambda
    it("should skip notification when record not found", async () => {
      const consoleInfoSpy = vi.spyOn(console, "info");
      
      // Simulate notification not found in DB
      const mockConsumeNotification = vi.spyOn(db, "consumeNotification");
      mockConsumeNotification.mockResolvedValue(undefined);

      const event: SQSEvent = {
        Records: [
          {
            messageId: "sqs-messsage-1",
            body: JSON.stringify({ notificationId: "missing-123" }),
          } as any,
        ],
      };
      const result = await main.handler(event, {} as any, {} as any);

      expect(result.batchItemFailures).toHaveLength(0);
    });

    it("should handle partial batch failures correctly", async () => {
      const consoleInfoSpy = vi.spyOn(console, "info");
      
      const mockConsumeNotification = vi.spyOn(db, "consumeNotification");
      mockConsumeNotification
        .mockResolvedValueOnce({
          NotificationID: "notificationId-1",
          Emails: ["test@cds-snc.ca"],
          Subject: "Subject 1",
          Body: "Body 1",
        })
        .mockResolvedValueOnce({
          NotificationID: "notificationId-2",
          Emails: ["test@cds-snc.ca"],
          Subject: "Subject 2",
          Body: "Body 2",
        })
        .mockResolvedValueOnce({
          NotificationID: "notificationId-3",
          Emails: ["test@cds-snc.ca"],
          Subject: "Subject 3",
          Body: "Body 3",
        })
        .mockResolvedValueOnce(undefined); // Fourth not found in DB (skipped)

      const mockSendNotification = vi.spyOn(email, "sendNotification");
      mockSendNotification
        .mockResolvedValueOnce(undefined) // First succeeds
        .mockRejectedValueOnce(new Error("Email service error")) // Second fails
        .mockResolvedValueOnce(undefined); // Third succeeds

      const event: SQSEvent = {
        Records: [
          { messageId: "sqs-messsage-1", body: JSON.stringify({ notificationId: "notificationId-1" }) } as any,
          { messageId: "sqs-messsage-2", body: JSON.stringify({ notificationId: "notificationId-2" }) } as any,
          { messageId: "sqs-messsage-3", body: JSON.stringify({ notificationId: "notificationId-3" }) } as any,
          { messageId: "sqs-messsage-4", body: JSON.stringify({ notificationId: "notificationId-4" }) } as any,
        ],
      };

      const result = await main.handler(event, {} as any, {} as any);

      expect(result.batchItemFailures).toHaveLength(1);
      expect(result.batchItemFailures[0].itemIdentifier).toBe("sqs-messsage-2");
      expect(mockSendNotification).toHaveBeenCalledTimes(3); // Only called for messages 1, 2, 3 (not 4)
      expect(consoleInfoSpy).toHaveBeenCalledWith(
        expect.stringContaining("{\"level\":\"info\",\"status\":\"failed\",\"msg\":\"Failed to process notification\",\"error\":\"Email service error\"}")
      );
    });
  });
});

describe("Notification Lambda Handler message data validation", () => {
    afterEach(() => {
        vi.clearAllMocks();
    });

    it("should fail when notification has no Emails", async () => {
      const consoleInfoSpy = vi.spyOn(console, "info");
 
      const mockConsumeNotification = vi.spyOn(db, "consumeNotification");
      mockConsumeNotification.mockResolvedValue({
        NotificationID: "notificationId-1",
        Emails: [], // Invalid: empty array
        Subject: "Test Subject",
        Body: "Test Body",
      });

      const event: SQSEvent = {
        Records: [
          {
            messageId: "sqs-messsage-1",
            body: JSON.stringify({ notificationId: "notificationId-1" }),
          } as any,
        ],
      };

      const result = await main.handler(event, {} as any, {} as any);

      expect(result.batchItemFailures).toHaveLength(1);
      expect(result.batchItemFailures[0].itemIdentifier).toBe("sqs-messsage-1");

      expect(consoleInfoSpy).toHaveBeenCalledWith(
        expect.stringContaining("{\"level\":\"info\",\"status\":\"failed\",\"msg\":\"Failed to process notification\",\"error\":\"Skipping due to invalid stored data id notificationId-1\"}")
      );
    });

    it("should fail when emails is undefined", async () => {
      const consoleInfoSpy = vi.spyOn(console, "info");

      const mockConsumeNotification = vi.spyOn(db, "consumeNotification");
      mockConsumeNotification.mockResolvedValue({
        NotificationID: "notificationId-1",
        Emails: undefined as any, // Invalid: undefined
        Subject: "Test Subject",
        Body: "Test Body",
      });

      const event: SQSEvent = {
        Records: [
          { messageId: "sqs-messsage-1", body: JSON.stringify({ notificationId: "notificationId-1" }) } as any,
        ],
      };

      const result = await main.handler(event, {} as any, {} as any);
      expect(result.batchItemFailures).toHaveLength(1);

      expect(consoleInfoSpy).toHaveBeenCalledWith(
        expect.stringContaining("{\"level\":\"info\",\"status\":\"failed\",\"msg\":\"Failed to process notification\",\"error\":\"Skipping due to invalid stored data id notificationId-1\"}")
      );      
    });

    it("should fail when subject is missing", async () => {
      const consoleInfoSpy = vi.spyOn(console, "info");

      const mockConsumeNotification = vi.spyOn(db, "consumeNotification");
      mockConsumeNotification.mockResolvedValue({
        NotificationID: "notificationId-1",
        Emails: ["test@cds-snc.ca"],
        Subject: "", // Invalid: empty subject
        Body: "Test Body",
      });

      const event: SQSEvent = {
        Records: [
          { messageId: "sqs-messsage-1", body: JSON.stringify({ notificationId: "notificationId-1" }) } as any,
        ],
      };

      const result = await main.handler(event, {} as any, {} as any);
      expect(result.batchItemFailures).toHaveLength(1);

      expect(consoleInfoSpy).toHaveBeenCalledWith(
        expect.stringContaining("{\"level\":\"info\",\"status\":\"failed\",\"msg\":\"Failed to process notification\",\"error\":\"Skipping due to invalid stored data id notificationId-1\"}")
      ); 
    });

    it("should return false when body is missing", async () => {
      const consoleInfoSpy = vi.spyOn(console, "info");

      const mockConsumeNotification = vi.spyOn(db, "consumeNotification");
      mockConsumeNotification.mockResolvedValue({
        NotificationID: "notificationId-1",
        Emails: ["test@cds-snc.ca"],
        Subject: "Test Subject",
        Body: undefined as any, // Invalid: undefined body
      });

      const event: SQSEvent = {
        Records: [
          { messageId: "sqs-messsage-1", body: JSON.stringify({ notificationId: "notificationId-1" }) } as any,
        ],
      };

      const result = await main.handler(event, {} as any, {} as any);
      expect(result.batchItemFailures).toHaveLength(1);

      expect(consoleInfoSpy).toHaveBeenCalledWith(
        expect.stringContaining("{\"level\":\"info\",\"status\":\"failed\",\"msg\":\"Failed to process notification\",\"error\":\"Skipping due to invalid stored data id notificationId-1\"}")
      ); 
    });

    it("should handle malformed JSON in message body", async () => {
      const consoleInfoSpy = vi.spyOn(console, "info");
      
      const event: SQSEvent = {
        Records: [
          {
            messageId: "sqs-messsage-1",
            body: "not valid json",
          } as any,
        ],
      };

      const result = await main.handler(event, {} as any, {} as any);

      expect(result.batchItemFailures).toHaveLength(1);

      expect(consoleInfoSpy).toHaveBeenCalledWith(
        expect.stringContaining("{\"level\":\"info\",\"status\":\"failed\",\"msg\":\"Failed to process notification\",\"error\":\"Unexpected token 'o', \\\"not valid json\\\" is not valid JSON\"}")
      ); 
    });    
});
