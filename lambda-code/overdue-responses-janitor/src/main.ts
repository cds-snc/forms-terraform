import { EitherAsyncUtils, lambdaWithValidatedEventAndContextualLogger } from "common";
import z from "zod";

type LambdaOutput = {
  numberOfOverdueResponsesConfirmed: number;
};

const lambdaEventSchema = z.object({
  formId: z.cuid2(),
});

export type OverdueResponsesJanitorPayload = z.infer<typeof lambdaEventSchema>;

export const handler = lambdaWithValidatedEventAndContextualLogger<OverdueResponsesJanitorPayload, LambdaOutput>(lambdaEventSchema, ({ event, contextualLogger }) => {
  return EitherAsyncUtils.right({ numberOfOverdueResponsesConfirmed: 2 } satisfies LambdaOutput);
});
