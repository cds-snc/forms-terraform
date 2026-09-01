import { LogFormatter, LogItem } from "@aws-lambda-powertools/logger";
import type {
  LogAttributes,
  UnformattedAttributes,
} from "@aws-lambda-powertools/logger/types";

export class ContextualLogFormatter extends LogFormatter {
  formatAttributes(
    attributes: UnformattedAttributes,
    additionalLogAttributes: LogAttributes,
  ): LogItem {
    const { error, severityLevel, ...gcFormsContext } = additionalLogAttributes;

    return new LogItem({
      attributes: {
        timestamp: this.formatTimestamp(attributes.timestamp),
        level: attributes.logLevel,
        message: attributes.message,
        ...(error !== undefined && {
          error: this.formatError(error as Error),
        }),
        ...(severityLevel !== undefined && {
          severityLevel: severityLevel as string,
        }),
        context: {
          gcForms: gcFormsContext,
          aws: {
            correlationIds: {
              awsRequestId: attributes.lambdaContext?.awsRequestId,
              xRayTraceId: attributes.xRayTraceId,
            },
            lambdaFunction: {
              coldStart: attributes.lambdaContext?.coldStart,
            },
          },
        },
      },
    });
  }
}
