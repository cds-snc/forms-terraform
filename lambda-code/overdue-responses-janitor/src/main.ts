import { EitherAsyncUtils, lambdaWithValidatedEventAndContextualLogger } from "common";
import z from "zod";

type LambdaOutput = {};

const lambdaEventSchema = z.object({
  formId: z.cuid2(),
});

export type OverdueResponsesJanitorPayload = z.infer<typeof lambdaEventSchema>;

export const handler = lambdaWithValidatedEventAndContextualLogger<OverdueResponsesJanitorPayload, LambdaOutput>(lambdaEventSchema, ({ event, contextualLogger }) => {
  return EitherAsyncUtils.right();
  //   const submissionId = uuid.v4();
  //   contextualLogger.addMetadata("submissionId", submissionId);
  //   contextualLogger.addMetadata("formId", submissionPayload.formID);
  //   return EitherAsyncUtils
  //     .right(findAttachmentsInResponses(submissionPayload.responses)) // biome-ignore format: To help keep the chain vertically aligned
  //     .chain((maybeAttachments) => {
  //       return maybeAttachments.caseOf({
  //         Just: (attachments) => handleSubmissionWithAttachments(submissionId, submissionPayload, attachments, contextualLogger),
  //         Nothing: () => handleSubmissionWithoutAttachments(submissionId, submissionPayload, contextualLogger),
  //       });
  //     })
  //     .ifRight(() =>
  //       contextualLogger.log({
  //         level: "info",
  //         message: "Submission processed successfully",
  //       }),
  //     )
  //     .ifLeft((error) =>
  //       contextualLogger.log({
  //         level: "error",
  //         message: "Submission processing failed",
  //         error,
  //         severityLevel: "1",
  //       }),
  //     );
});
