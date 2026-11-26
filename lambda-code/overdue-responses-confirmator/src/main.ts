import type { NativeAttributeValue } from "@aws-sdk/lib-dynamodb";
import { EitherAsyncUtils, type LambdaInvocationContextualLogger, lambdaWithValidatedEventAndContextualLogger } from "common";
import { EitherAsync } from "purify-ts";
import z from "zod";
import { confirmOverdueResponses, retrieveNextBatchOfOverdueResponses } from "./lib/vault.ts";

const DEFAULT_AGE_IN_DAYS_AFTER_RESPONSE_CONSIDERED_OVERDUE = 45;

const lambdaEventSchema = z.object({
  formId: z.cuid2(),
  ageInDaysAfterResponseConsideredOverdue: z.uint32().optional(),
});

type OverdueResponsesConfirmatorPayload = z.infer<typeof lambdaEventSchema>;

export const handler = lambdaWithValidatedEventAndContextualLogger<OverdueResponsesConfirmatorPayload, void>(lambdaEventSchema, ({ event, contextualLogger }) => {
  const selectedAgeInDaysAfterResponseConsideredOverdue = event.ageInDaysAfterResponseConsideredOverdue ?? DEFAULT_AGE_IN_DAYS_AFTER_RESPONSE_CONSIDERED_OVERDUE;

  contextualLogger.addMetadata("formId", event.formId);
  contextualLogger.addMetadata("ageInDaysAfterResponseConsideredOverdue", `${selectedAgeInDaysAfterResponseConsideredOverdue}`);

  return retrieveAndConfirmAllOverdueResponses(event.formId, selectedAgeInDaysAfterResponseConsideredOverdue, contextualLogger)
    .ifRight(({ numberOfConfirmedOverdueResponses, oldestOverdueResponseDate, newestOverdueResponseDate }) =>
      contextualLogger.log({
        level: "warn", // Set to WARN in order to receive the log in Slack
        message: buildSummaryLogMessage({
          formId: event.formId,
          ageInDaysAfterResponseConsideredOverdue: selectedAgeInDaysAfterResponseConsideredOverdue,
          numberOfConfirmedOverdueResponses,
          oldestOverdueResponseDate,
          newestOverdueResponseDate,
        }),
      }),
    )
    .void()
    .ifLeft((error) => contextualLogger.log({ level: "error", message: "No problemo... just a minor system malfunction.\n\nI'll be back!", error }));
});

function retrieveAndConfirmAllOverdueResponses(
  formId: string,
  ageInDaysAfterResponseConsideredOverdue: number,
  contextualLogger: LambdaInvocationContextualLogger,
): EitherAsync<Error, { numberOfConfirmedOverdueResponses: number; oldestOverdueResponseDate?: Date; newestOverdueResponseDate?: Date }> {
  function retrieveAndConfirmAllOverdueResponsesWithRecursion(
    numberOfConfirmedOverdueResponses: number = 0,
    oldestOverdueResponseDate?: Date,
    newestOverdueResponseDate?: Date,
    lastEvaluatedKey?: Record<string, NativeAttributeValue>,
  ): EitherAsync<Error, { numberOfConfirmedOverdueResponses: number; oldestOverdueResponseDate?: Date; newestOverdueResponseDate?: Date }> {
    return retrieveNextBatchOfOverdueResponses(formId, ageInDaysAfterResponseConsideredOverdue, lastEvaluatedKey)
      .chain(EitherAsyncUtils.ifRightAsync(({ overdueResponses }) => confirmOverdueResponses(formId, overdueResponses)))
      .chain(({ overdueResponses, lastEvaluatedKey }) => {
        const nextNumberOfConfirmedOverdueResponses = numberOfConfirmedOverdueResponses + overdueResponses.length;

        let nextOldestOverdueResponseDate = oldestOverdueResponseDate;
        let nextNewestOverdueResponseDate = newestOverdueResponseDate;

        if (overdueResponses.length > 0) {
          const firstOverdueResponseDate = new Date(overdueResponses[0].createdAt);
          const lastOverdueResponseDate = new Date(overdueResponses[overdueResponses.length - 1].createdAt);

          if (nextOldestOverdueResponseDate === undefined) {
            nextOldestOverdueResponseDate = firstOverdueResponseDate;
          }

          nextNewestOverdueResponseDate = lastOverdueResponseDate;

          contextualLogger.log({
            level: "info",
            message: `Targeting responses from ${firstOverdueResponseDate.toISOString()} to ${lastOverdueResponseDate.toISOString()}.\n\n${overdueResponses.length} new targets have been confirmed.\n\nTotal confirmed casualties: ${nextNumberOfConfirmedOverdueResponses}.`,
          });
        }

        if (lastEvaluatedKey === undefined) {
          return EitherAsyncUtils.right({
            numberOfConfirmedOverdueResponses: nextNumberOfConfirmedOverdueResponses,
            oldestOverdueResponseDate: nextOldestOverdueResponseDate,
            newestOverdueResponseDate: nextNewestOverdueResponseDate,
          });
        } else {
          // Delay next set of actions by 100 ms to avoid DynamoDB API rate limit
          return delayNextAction(100).chain(() =>
            retrieveAndConfirmAllOverdueResponsesWithRecursion(nextNumberOfConfirmedOverdueResponses, nextOldestOverdueResponseDate, nextNewestOverdueResponseDate, lastEvaluatedKey),
          );
        }
      });
  }

  return retrieveAndConfirmAllOverdueResponsesWithRecursion();
}

function delayNextAction(delayInMs: number): EitherAsync<Error, void> {
  return EitherAsync(() => new Promise((resolve) => setTimeout(resolve, delayInMs)));
}

function buildSummaryLogMessage(input: {
  formId: string;
  ageInDaysAfterResponseConsideredOverdue: number;
  numberOfConfirmedOverdueResponses: number;
  oldestOverdueResponseDate?: Date;
  newestOverdueResponseDate?: Date;
}): string {
  if (input.numberOfConfirmedOverdueResponses > 0) {
    return `
The Confirmator has confirmed ${input.numberOfConfirmedOverdueResponses} overdue responses (at least ${input.ageInDaysAfterResponseConsideredOverdue} days old).

Targeted form: ${input.formId}
Targeted responses: from ${input.oldestOverdueResponseDate?.toISOString() ?? "n/a"} to ${input.newestOverdueResponseDate?.toISOString() ?? "n/a"}

Hasta la vista, overdue responses!
`;
  } else {
    return `
The Confirmator has not found any overdue responses (at least ${input.ageInDaysAfterResponseConsideredOverdue} days old).

Targeted form: ${input.formId}

My work here is done. I'll be back!
`;
  }
}
