import { extractFileInputResponses } from "./dataLayer.js";
import { getFileMetaData } from "./s3FileInput.js";
import { FormSubmission } from "./types.js";

export class FileScanningCompletionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "FileScanningCompletionError";
  }
}

export const verifyFileScanCompletion = async (formSubmission: FormSubmission) => {
  const fileInputPaths = extractFileInputResponses(formSubmission);
  const fileMetaDataPromises = fileInputPaths.map((filePath) => getFileMetaData(filePath));

  const fileMetaData = await Promise.allSettled(fileMetaDataPromises).then((results) => {
    return results.map((result) => {
      if (result.status === "fulfilled") {
        return result.value;
      } else {
        console.error(`Error retrieving metadata for file: ${result.reason}`);
        return undefined;
      }
    });
  });

  fileMetaData.forEach((meta, index) => {
    console.info(`File ${fileInputPaths[index]} Metadata: ${JSON.stringify(meta)}`);
  });

  return fileMetaData.every((meta) =>
    meta?.some((tag) => tag.Key === "GuardDutyMalwareScanStatus")
  );
};
