import { lambdaWithSqsBatchProcessingAndContextualLogger } from "common";
import { type Either, EitherAsync, Left, Right } from "purify-ts";

export const handler = lambdaWithSqsBatchProcessingAndContextualLogger(({ event, contextualLogger }) => {
  return EitherAsync.liftEither(extractSubmissionIdentifierFromSqsRecordBody(event.body)).void();
  // contextualLogger.addMetadata("messageId", event.messageId);
  // return EitherAsync.fromPromise<Error, void>(async () => {
  //   try {
  //     contextualLogger.log({ level: "info", message: `messageId = ${event.messageId}` });
  //     return Right(undefined);
  //   } catch (err) {
  //     return Left(err as Error);
  //   }
  // });
});

function extractSubmissionIdentifierFromSqsRecordBody(body: string): Either<Error, string> {
  const { submissionID } = JSON.parse(body) as { submissionID?: string };

  if (submissionID === undefined) {
    return Left(new Error("submissionID is undefined in SQS record"));
  }

  return Right(submissionID);
}
