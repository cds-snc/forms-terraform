import type { PresignedPost } from "@aws-sdk/s3-presigned-post";
import { type ContextualLogger, lambdaWithContextualLogger } from "common";
import { EitherAsync } from "purify-ts";
import * as uuid from "uuid";
import { type Attachment, associateAttachmentWithCorrespondingChecksum, generateAttachmentS3AccessKeys, generateAttachmentUploadUrls, searchForAttachmentsInResponses } from "./lib/attachments.ts";
import { extractSubmissionPayloadFromLambdaEvent, type SubmissionPayload } from "./lib/payload.ts";
import { enqueueDelayedSubmissionProcessingRequest } from "./lib/processing.ts";
import { attachSubmissionProcessingRequestIdToSavedSubmission, saveSubmissionToReliabilityStorage } from "./lib/storage.ts";

type LambdaEvent = Record<string, unknown>;

type LambdaResult = {
  submissionId: string;
  fileURLMap?: Record<string, PresignedPost>;
};

const SUBMISSION_PROCESSING_REQUEST_DELAY_IN_SECONDS = 5; // Helps ensure the file scanning job is processed first

export const handler = lambdaWithContextualLogger<LambdaEvent, LambdaResult>(({ event, contextualLogger }) => {
  return EitherAsync
    .liftEither(extractSubmissionPayloadFromLambdaEvent(event)) // biome-ignore format: To help keep the chain vertically aligned
    .ifRight(({ formID }) => contextualLogger.addMetadata("formId", formID))
    .chain((submissionPayload) => EitherAsync.liftEither(searchForAttachmentsInResponses(submissionPayload.responses)).map((detectedAttachments) => ({ submissionPayload, detectedAttachments })))
    .chain(({ submissionPayload, detectedAttachments }) => {
      const submissionId = uuid.v4();

      contextualLogger.addMetadata("submissionId", submissionId);

      return detectedAttachments.length > 0
        ? handleSubmissionWithAttachments(submissionId, submissionPayload, detectedAttachments, contextualLogger)
        : handleSubmissionWithoutAttachments(submissionId, submissionPayload, contextualLogger);
    })
    .ifRight(() =>
      contextualLogger.log({
        level: "info",
        message: "Submission processed successfully",
      }),
    )
    .ifLeft((error) =>
      contextualLogger.log({
        level: "error",
        message: "Submission processing failed",
        error: error as Error,
        severityLevel: "1",
      }),
    );
});

function handleSubmissionWithoutAttachments(submissionId: string, submissionPayload: SubmissionPayload, contextualLogger: ContextualLogger): EitherAsync<Error, LambdaResult> {
  return saveSubmissionToReliabilityStorage(submissionId, submissionPayload)
    .chain(() =>
      enqueueDelayedSubmissionProcessingRequest(submissionId, SUBMISSION_PROCESSING_REQUEST_DELAY_IN_SECONDS).map(({ submissionProcessingRequestId }) => ({
        submissionId,
        submissionProcessingRequestId,
      })),
    )
    .ifRight(({ submissionProcessingRequestId }) => contextualLogger.addMetadata("submissionProcessingRequestId", submissionProcessingRequestId))
    .chain(({ submissionId, submissionProcessingRequestId }) =>
      attachSubmissionProcessingRequestIdToSavedSubmission(submissionId, submissionProcessingRequestId).map(() => ({
        submissionId,
      })),
    )
    .map(({ submissionId }) => ({ submissionId }) satisfies LambdaResult);
}

function handleSubmissionWithAttachments(submissionId: string, submissionPayload: SubmissionPayload, attachments: Attachment[], contextualLogger: ContextualLogger): EitherAsync<Error, LambdaResult> {
  contextualLogger.log({ level: "info", message: `Attachment(s) detected:\n${attachments.map((a) => `- ID: ${a.id} / size = ${a.size} bytes`).join("\n")}` });

  if (submissionPayload.fileChecksums === undefined) {
    // TODO: make sure this throw is propagated in the EitherAsync chain
    throw new Error("Attachments have been detected in the responses but no content MD5 checksums were provided");
  }

  return EitherAsync
    .liftEither(associateAttachmentWithCorrespondingChecksum(attachments, submissionPayload.fileChecksums)) // biome-ignore format: To help keep the chain vertically aligned
    .chain((attachmentWithChecksums) => EitherAsync.liftEither(generateAttachmentS3AccessKeys(submissionId, attachmentWithChecksums)))
    .chain((attachmentS3AccessKeys) => generateAttachmentUploadUrls(attachmentS3AccessKeys))
    .chain((attachmentS3UploadUrls) =>
      saveSubmissionToReliabilityStorage(
        submissionId,
        submissionPayload,
        attachmentS3UploadUrls.map((a) => a.s3AccessKey),
      ).map(() => ({ attachmentS3UploadUrls })),
    )
    .map(({ attachmentS3UploadUrls }) => ({ submissionId, fileURLMap: Object.fromEntries(attachmentS3UploadUrls.map((v) => [v.id, v.s3UploadUrl])) }) satisfies LambdaResult);
}
