import { parse } from "@aws-lambda-powertools/parser";
import { type Either, Left, Right } from "purify-ts";
import z from "zod";

export type SubmissionPayload = {
  formID: string;
  language: string;
  responses: Record<string, unknown>;
  securityAttribute: string;
  fileChecksums?: Record<string, string>;
  version?: number;
  notificationId?: string;
};

const lambdaEventSchema = z.object({
  formID: z.cuid2(),
  language: z.enum(["en", "fr"]),
  responses: z.record(z.string(), z.unknown()), // In the future, we could even validate the inside of the `responses` object
  securityAttribute: z.enum(["Unclassified", "Protected A", "Protected B"]),
  fileChecksums: z.record(z.string(), z.string()).optional(),
  version: z.uint32().positive().optional(),
  notificationId: z.uuidv4().optional(),
});

export function extractSubmissionPayloadFromLambdaEvent(event: Record<string, unknown>): Either<Error, SubmissionPayload> {
  const parsedResult = parse(event, undefined, lambdaEventSchema, true);

  return parsedResult.success
    ? Right(parsedResult.data satisfies SubmissionPayload)
    : Left(
        new Error("Failed to parse lambda event", {
          cause: parsedResult.error,
        }),
      );
}
