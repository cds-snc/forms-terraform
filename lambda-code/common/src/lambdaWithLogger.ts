import type { Context } from "aws-lambda";
import { ContextualLogger } from "./contextualLogger.ts";

export function asyncLambdaWithLogger<Event, Result>(
  handler: (
    event: Event,
    context: Context,
    contextualLogger: ContextualLogger,
  ) => Promise<Result>,
) {
  return async (event: Event, context: Context): Promise<Result> =>
    ContextualLogger.use((contextualLogger) =>
      handler(event, context, contextualLogger),
    );
}
