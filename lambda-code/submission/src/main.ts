import type { PresignedPost } from "@aws-sdk/s3-presigned-post";
import { EitherAsyncUtils, type LambdaInvocationContextualLogger, lambdaWithValidatedEventAndContextualLogger } from "common";
import { EitherAsync } from "purify-ts";
import * as uuid from "uuid";
import z from "zod";
import { saveProcessableSubmission } from "./lib/processableSubmissionStore.ts";
import {
  type Attachment,
  type AttachmentWithS3UploadUrl,
  associateAttachmentWithCorrespondingChecksum,
  findAttachmentsInResponses,
  generateAttachmentS3AccessKeys,
  generateAttachmentUploadUrls,
} from "./lib/submissionAttachments.ts";
import { enqueueDelayedSubmissionProcessingRequest } from "./lib/submissionProcessingEnqueuer.ts";

const lambdaEventSchema = z.object({
  formID: z.cuid2(),
  language: z.enum(["en", "fr"]),
  responses: z.record(z.string(), z.unknown()), // In the future, we could even validate the inside of the `responses` object
  securityAttribute: z.enum(["Unclassified", "Protected A", "Protected B"]),
  fileChecksums: z.record(z.string(), z.string()).optional(),
  version: z.uint32().positive().optional(),
  notificationId: z.uuidv4().optional(),
});

type SubmissionPayload = z.infer<typeof lambdaEventSchema>;

type LambdaOutput = {
  submissionId: string;
  fileURLMap?: Record<string, PresignedPost>;
};

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
    .chain((attachmentsWithChecksum) => EitherAsyncUtils.right(generateAttachmentS3AccessKeys(submissionId, attachmentsWithChecksum)))
    .ifRight((attachmentsWithS3AccessKey) => contextualLogger.addMetadata("attachments", JSON.stringify(attachmentsWithS3AccessKey)))
    .chain((attachmentsWithS3AccessKey) => generateAttachmentUploadUrls(attachmentsWithS3AccessKey))
    .chain(EitherAsyncUtils.ifRightAsync((attachmentsWithS3UploadUrl) => saveSubmission(submissionId, submissionPayload, attachmentsWithS3UploadUrl)))
    .map((attachmentsWithS3UploadUrl) => ({ submissionId, fileURLMap: Object.fromEntries(attachmentsWithS3UploadUrl.map((v) => [v.id, v.s3UploadUrl])) }) satisfies LambdaOutput);
}

function handleSubmissionWithoutAttachments(submissionId: string, submissionPayload: SubmissionPayload, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, LambdaOutput> {
  return saveSubmission(submissionId, submissionPayload)
    .chain(() => enqueueDelayedSubmissionProcessingRequest(submissionId))
    .ifRight(({ submissionProcessingRequestId }) => contextualLogger.addMetadata("submissionProcessingRequestId", submissionProcessingRequestId))
    .map(() => ({ submissionId }) satisfies LambdaOutput);
}

function saveSubmission(submissionId: string, submissionPayload: SubmissionPayload, attachmentsWithS3UploadUrl?: AttachmentWithS3UploadUrl[]): EitherAsync<Error, void> {
  return saveProcessableSubmission({
    id: submissionId,
    associatedFormId: submissionPayload.formID,
    language: submissionPayload.language,
    responses: submissionPayload.responses,
    securityAttribute: submissionPayload.securityAttribute,
    version: submissionPayload.version ?? 1,
    attachmentS3AccessKeys: attachmentsWithS3UploadUrl?.map((a) => a.s3AccessKey),
    notificationId: submissionPayload.notificationId,
  });
}
