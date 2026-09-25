import { EitherAsyncUtils, type LambdaInvocationContextualLogger } from "common";
import type { EitherAsync } from "purify-ts";

export type EmailProcessableSubmission = {
  id: string;
  associatedFormId: string;
  createdAt: number;
  language: string;
  responsesAsJson: string;
  attachmentPaths?: string[];
};

export function handleWithEmailPipeline(processableSubmission: EmailProcessableSubmission, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  return EitherAsyncUtils.right();
}

// function emailPipelineWithAttachments(processableSubmission: ProcessableSubmission, formTemplate: FormTemplate, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
//   return EitherAsyncUtils.done();
// }
