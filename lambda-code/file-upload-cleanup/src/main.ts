import { Handler } from "aws-lambda";

import { getSubmissionsToVerify, cleanupFailedUploads } from "@lib/datalayer.js";

export const handler: Handler = async () => {
  const fileKeysToCheck = await getSubmissionsToVerify();
  const results = await cleanupFailedUploads(fileKeysToCheck);
  results.forEach((result) => {
    if (result.status === "rejected") {
      console.error(result.reason);
    }
  });
};
