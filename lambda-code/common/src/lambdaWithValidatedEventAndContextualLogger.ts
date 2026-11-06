import { parse } from "@aws-lambda-powertools/parser";
import type { Context } from "aws-lambda";
import { type Either, Left, Right } from "purify-ts";
import { EitherAsync } from "purify-ts/EitherAsync";
import type z from "zod";
import { DefaultLambdaInvocationContextualLogger, type LambdaInvocationContextualLogger } from "./logger/lambdaInvocationContextualLogger.ts";

const contextualLogger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

export function lambdaWithValidatedEventAndContextualLogger<Input, Output>(
  eventSchema: z.ZodType<Input>,
  handler: (params: { event: Input; context: Context; contextualLogger: LambdaInvocationContextualLogger }) => EitherAsync<Error, Output>,
) {
  return async (event: unknown, context: Context): Promise<Output> => {
    contextualLogger.startInvocationContext(context);

    return EitherAsync.liftEither(validateEvent(event, eventSchema))
      .chain((validatedEvent) => handler({ event: validatedEvent, context, contextualLogger }))
      .caseOf({
        Left: (error) => {
          contextualLogger.log({ level: "error", message: "An error occurred during Lambda execution", error });
          throw error;
        },
        Right: (output) => output,
      })
      .finally(() => {
        contextualLogger.endInvocationContext();
      });
  };
}

function validateEvent<Input>(event: unknown, schema: z.ZodType<Input>): Either<Error, Input> {
  const parsedResult = parse(event, undefined, schema, true);

  if (parsedResult.success === true) {
    return Right(parsedResult.data);
  } else {
    return Left(new Error("Failed to validate lambda event", { cause: parsedResult.error }));
  }
}
