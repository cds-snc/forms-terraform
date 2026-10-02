import { BatchProcessor, EventType, processPartialResponse } from "@aws-lambda-powertools/batch";
import type { Context, SQSBatchResponse, SQSEvent, SQSRecord } from "aws-lambda";
import type { EitherAsync } from "purify-ts/EitherAsync";
import { DefaultLambdaInvocationContextualLogger, type LambdaInvocationContextualLogger } from "./logger/lambdaInvocationContextualLogger.ts";

const sqsBatchProcessor = new BatchProcessor(EventType.SQS);
const contextualLogger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

export function lambdaWithSqsBatchProcessingAndContextualLogger(
  handler: (params: { event: SQSRecord; context: Context; contextualLogger: LambdaInvocationContextualLogger }) => EitherAsync<Error, void>,
) {
  return async (event: SQSEvent, context: Context): Promise<SQSBatchResponse> => {
    contextualLogger.startInvocationContext(context);

    async function recordHandler(sqsRecord: SQSRecord) {
      return handler({ event: sqsRecord, context, contextualLogger: contextualLogger.createChildLogger() }).caseOf({
        Left: (error) => {
          throw error;
        },
        Right: (output) => output,
      });
    }

    return processPartialResponse(event, recordHandler, sqsBatchProcessor, { context, processInParallel: true }).finally(() => {
      contextualLogger.endInvocationContext();
    });
  };
}
