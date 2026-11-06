import { TransactionCanceledException } from "@aws-sdk/client-dynamodb";
import { TransactWriteCommand } from "@aws-sdk/lib-dynamodb";
import { EitherAsync, Left } from "purify-ts";
import { v4 as uuidV4 } from "uuid";
import { dynamodbClient } from "./awsServicesConnector.ts";

class DuplicateSubmissionNameError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "DuplicateSubmissionNameError";
  }
}

export function saveSubmissionWithUniqueName(input: {
  submissionId: string;
  formId: string;
  createdAt: number;
  language: string;
  securityAttribute: string;
  version: number;
  responsesAsJson: string;
  attachmentsAsJson: string;
  responsesHash: string;
}): EitherAsync<Error, void> {
  return saveSubmission({
    submissionId: input.submissionId,
    formId: input.formId,
    name: generateSubmissionName(input.submissionId, input.createdAt),
    createdAt: input.createdAt,
    language: input.language,
    securityAttribute: input.securityAttribute,
    version: input.version,
    confirmationCode: uuidV4(),
    responsesAsJson: input.responsesAsJson,
    attachmentsAsJson: input.attachmentsAsJson,
    responsesHash: input.responsesHash,
  }).chainLeft((error) => {
    if (error instanceof DuplicateSubmissionNameError) {
      return saveSubmissionWithUniqueName(input);
    } else {
      return EitherAsync.liftEither(Left(error));
    }
  });
}

function generateSubmissionName(submissionId: string, submissionCreatedAt: number, withRandomSuffix: boolean = false): string {
  const submissionDate = new Date(submissionCreatedAt);
  let submissionNameSuffix = submissionId.substring(0, 5);

  if (withRandomSuffix) {
    const letters = "abcdefghijklmnopqrstuvwxyz";
    const characters = `${letters}0123456789`;
    let result = "";

    // Ensure at least one letter
    result += letters.charAt(Math.floor(Math.random() * letters.length));

    for (let i = 1; i < 5; i++) {
      result += characters.charAt(Math.floor(Math.random() * characters.length));
    }

    // Shuffle result to avoid always starting with a letter
    submissionNameSuffix = result
      .split("")
      .sort(() => 0.5 - Math.random())
      .join("");
  }

  return `${(`0${submissionDate.getDate()}`).slice(-2)}-${(`0${submissionDate.getMonth() + 1}`).slice(-2)}-${submissionNameSuffix}`;
}

function saveSubmission(input: {
  submissionId: string;
  formId: string;
  name: string;
  createdAt: number;
  language: string;
  securityAttribute: string;
  version: number;
  confirmationCode: string;
  responsesAsJson: string;
  attachmentsAsJson: string;
  responsesHash: string;
}): EitherAsync<Error | DuplicateSubmissionNameError, void> {
  return EitherAsync(() =>
    dynamodbClient.send(
      new TransactWriteCommand({
        TransactItems: [
          {
            Put: {
              TableName: process.env.DYNAMODB_VAULT_TABLE_NAME,
              // Prevent overwriting an existing item with the same FormID and NAME_OR_CONF.
              // If the submission name already exists for this form, the transaction fails
              ConditionExpression: "attribute_not_exists(NAME_OR_CONF)",
              Item: {
                SubmissionID: input.submissionId,
                FormID: input.formId,
                NAME_OR_CONF: `NAME#${input.name}`,
                FormSubmission: input.responsesAsJson,
                FormSubmissionLanguage: input.language,
                CreatedAt: input.createdAt,
                SecurityAttribute: input.securityAttribute,
                Version: input.version,
                "Status#CreatedAt": `New#${input.createdAt}`,
                ConfirmationCode: input.confirmationCode,
                Name: input.name,
                FormSubmissionHash: input.responsesHash,
                SubmissionAttachments: input.attachmentsAsJson,
              },
            },
          },
          {
            Put: {
              TableName: process.env.DYNAMODB_VAULT_TABLE_NAME,
              Item: {
                FormID: input.formId,
                NAME_OR_CONF: `CONF#${input.confirmationCode}`,
                Name: input.name,
                CreatedAt: input.createdAt,
                ConfirmationCode: input.confirmationCode,
              },
            },
          },
        ],
      }),
    ),
  )
    .void()
    .mapLeft((error) => {
      if (error instanceof TransactionCanceledException) {
        const didConditionalCheckFail = error.CancellationReasons?.find((reason) => reason.Code === "ConditionalCheckFailed") !== undefined;

        if (didConditionalCheckFail) {
          return new DuplicateSubmissionNameError(`Submission name '${input.name}' already exists`);
        }
      }

      return new Error("Failed to save submission to Vault storage", { cause: error });
    });
}
