import { asyncLambdaWithLogger } from "common";

interface Submission {
  name: string;
}

export const handler = asyncLambdaWithLogger<Submission, boolean>(
  async (event, context, contextualLogger) => {
    if (event satisfies { name: string }) {
      //
    }
    // satisfies
    return true;
  },
);
