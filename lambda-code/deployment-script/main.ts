import { Handler } from "aws-lambda";
import { prismaMigrate } from "./lib/prisma.js";
import { syncS3 } from "./lib/file_sync.js";

export const handler: Handler = async (event: { [key: string]: any }) => {
  const s3BucketName = "forms-730335263169-deployment-script-storage";
  await syncS3(s3BucketName, "/tmp");
  await prismaMigrate();
};

if (process.env.AWS_PROFILE === "development") {
  // Mock event, context, and callback for testing
  const mockEvent = {};
  const mockContext = {} as any;
  const mockCallback = () => {};

  handler(mockEvent, mockContext, mockCallback);
}
