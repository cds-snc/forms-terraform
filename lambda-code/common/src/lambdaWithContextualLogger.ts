import type { Context, Handler } from "aws-lambda";
import type { EitherAsync } from "purify-ts/EitherAsync";
import { DefaultLambdaInvocationContextualLogger, type LambdaInvocationContextualLogger } from "./logger/lambdaInvocationContextualLogger.ts";

const contextualLogger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

export function lambdaWithContextualLogger<Input, Output>(
  handler: (params: { event: Input; context: Context; contextualLogger: LambdaInvocationContextualLogger }) => EitherAsync<Error, Output>,
): Handler {
  return async (event: Input, context: Context): Promise<Output> => {
    contextualLogger.startInvocationContext(context);

    return handler({ event, context, contextualLogger })
      .caseOf({
        Left: (error) => {
          throw error;
        },
        Right: (output) => output,
      })
      .finally(() => {
        contextualLogger.endInvocationContext();
      });
  };
}
