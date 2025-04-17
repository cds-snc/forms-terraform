import { Handler } from "aws-lambda";

import { syncS3 } from "lib/file_sync.js";

export const handler: Handler = async (event: { [key: string]: any }) => {
  const s3BucketName = "forms-730335263169-deployment-script-storage";
  await syncS3(s3BucketName, "/tmp");
};

// Mock event, context, and callback for testing
const mockEvent = {};
const mockContext = {} as any;
const mockCallback = () => {};

handler(mockEvent, mockContext, mockCallback);
