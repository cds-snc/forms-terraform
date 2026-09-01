import type { Context } from "aws-lambda";
import type { EitherAsync } from "purify-ts/EitherAsync";
import {
  type ContextualLogger,
  DefaultContextualLogger,
} from "./logger/contextualLogger.ts";

const contextualLogger = new DefaultContextualLogger();

export function lambdaWithContextualLogger<Input, Output>(
  handler: (params: {
    event: Input;
    context: Context;
    contextualLogger: ContextualLogger;
  }) => EitherAsync<Error, Output>,
) {
  return async (event: Input, context: Context): Promise<Output> => {
    contextualLogger.addContext(context);

    const handlerResult = await handler({ event, context, contextualLogger });

    return handlerResult.caseOf({
      Left: (error) => {
        throw error;
      },
      Right: (output) => output,
    });
  };
}
