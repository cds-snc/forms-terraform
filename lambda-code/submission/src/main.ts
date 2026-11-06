import type { PresignedPost } from "@aws-sdk/s3-presigned-post";
import { EitherAsyncUtils, type LambdaInvocationContextualLogger, lambdaWithValidatedEventAndContextualLogger } from "common";
import { EitherAsync } from "purify-ts";
import * as uuid from "uuid";
import z from "zod";
import { type Attachment, associateAttachmentWithCorrespondingChecksum, findAttachmentsInResponses, generateAttachmentS3AccessKeys, generateAttachmentUploadUrls } from "./lib/attachments.ts";
import { enqueueDelayedSubmissionProcessingRequest } from "./lib/processing.ts";
import { saveProcessableSubmission } from "./lib/storage.ts";

type LambdaOutput = {
  submissionId: string;
  fileURLMap?: Record<string, PresignedPost>;
};

const lambdaEventSchema = z.object({
  formID: z.cuid2(),
  language: z.enum(["en", "fr"]),
  responses: z.record(z.string(), z.unknown()), // In the future, we could even validate the inside of the `responses` object
  securityAttribute: z.enum(["Unclassified", "Protected A", "Protected B"]),
  fileChecksums: z.record(z.string(), z.string()).optional(),
  version: z.uint32().positive().optional(),
  notificationId: z.uuidv4().optional(),
});

export type SubmissionPayload = z.infer<typeof lambdaEventSchema>;

const SUBMISSION_PROCESSING_REQUEST_DELAY_IN_SECONDS = 5;

export const handler = lambdaWithValidatedEventAndContextualLogger<SubmissionPayload, LambdaOutput>(lambdaEventSchema, ({ event: submissionPayload, contextualLogger }) => {
  const submissionId = uuid.v4();

  contextualLogger.addMetadata("submissionId", submissionId);
  contextualLogger.addMetadata("formId", submissionPayload.formID);

  return EitherAsyncUtils
    .right(findAttachmentsInResponses(submissionPayload.responses)) // biome-ignore format: To help keep the chain vertically aligned
    .chain((maybeAttachments) => {
      return maybeAttachments.caseOf({
        Just: (attachments) => handleSubmissionWithAttachments(submissionId, submissionPayload, attachments, contextualLogger),
        Nothing: () => handleSubmissionWithoutAttachments(submissionId, submissionPayload, contextualLogger),
      });
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
        error,
        severityLevel: "1",
      }),
    );
});

function handleSubmissionWithAttachments(
  submissionId: string,
  submissionPayload: SubmissionPayload,
  attachments: Attachment[],
  contextualLogger: LambdaInvocationContextualLogger,
): EitherAsync<Error, LambdaOutput> {
  contextualLogger.addMetadata("attachments", JSON.stringify(attachments));

  if (submissionPayload.fileChecksums === undefined) {
    return EitherAsyncUtils.left(new Error("Attachments have been detected in the responses but no content MD5 checksums were provided"));
  }

  return EitherAsync
    .liftEither(associateAttachmentWithCorrespondingChecksum(attachments, submissionPayload.fileChecksums)) // biome-ignore format: To help keep the chain vertically aligned
    .chain((attachmentWithChecksums) => EitherAsyncUtils.right(generateAttachmentS3AccessKeys(submissionId, attachmentWithChecksums)))
    .ifRight((attachmentS3AccessKeys) => contextualLogger.addMetadata("attachmentS3AccessKeys", JSON.stringify(attachmentS3AccessKeys)))
    .chain((attachmentS3AccessKeys) => generateAttachmentUploadUrls(attachmentS3AccessKeys))
    .chain(
      EitherAsyncUtils.ifRightAsync((attachmentS3UploadUrls) =>
        saveProcessableSubmission(
          submissionId,
          submissionPayload,
          attachmentS3UploadUrls.map((a) => a.s3AccessKey),
        ),
      ),
    )
    .map((attachmentS3UploadUrls) => ({ submissionId, fileURLMap: Object.fromEntries(attachmentS3UploadUrls.map((v) => [v.id, v.s3UploadUrl])) }) satisfies LambdaOutput);
}

function handleSubmissionWithoutAttachments(submissionId: string, submissionPayload: SubmissionPayload, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, LambdaOutput> {
  return saveProcessableSubmission(submissionId, submissionPayload)
    .chain(() => enqueueDelayedSubmissionProcessingRequest(submissionId, SUBMISSION_PROCESSING_REQUEST_DELAY_IN_SECONDS))
    .ifRight(({ submissionProcessingRequestId }) => contextualLogger.addMetadata("submissionProcessingRequestId", submissionProcessingRequestId))
    .map(() => ({ submissionId }) satisfies LambdaOutput);
}
