import type { LambdaInvocationContextualLogger } from "common";
import type { EitherAsync } from "purify-ts";
import { EitherAsyncUtils } from "../main.ts";

export type EmailProcessableSubmission = {
  id: string;
  associatedFormId: string;
  createdAt: number;
  language: string;
  responsesAsJson: string;
  attachmentPaths?: string[];
};

export function emailPipeline(processableSubmission: EmailProcessableSubmission, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  return EitherAsyncUtils.done();
}

// function emailPipelineWithAttachments(processableSubmission: ProcessableSubmission, formTemplate: FormTemplate, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
//   return EitherAsyncUtils.done();
// }
