import { Handler } from "aws-lambda";
import { IdpClient } from "@lib/idpClient.js";
import { ApiClient } from "@lib/apiClient.js";
import { SubmissionGenerator } from "@lib/submissionGenerator.js";
import { CommonUseCaseTest } from "@tests/commonUseCaseTest.js";
import { RateLimiterTest } from "@tests/rateLimiterTest.js";

const IDP_TRUSTED_DOMAIN: string = process.env.IDP_TRUSTED_DOMAIN ?? "";
const IDP_URL: string = process.env.IDP_URL ?? "";
const IDP_PROJECT_IDENTIFIER: string = process.env.IDP_PROJECT_IDENTIFIER ?? "";
const API_URL: string = process.env.API_URL ?? "";
const FORM_ID: string = process.env.FORM_ID ?? "";
const API_PRIVATE_KEY: string = process.env.API_PRIVATE_KEY ?? "";

export const handler: Handler = async () => {
  try {
    const submissionGenerator = new SubmissionGenerator(FORM_ID);

    const privateApiKey = JSON.parse(API_PRIVATE_KEY) as PrivateApiKey;

    const idpClient = new IdpClient(
      IDP_TRUSTED_DOMAIN,
      IDP_URL,
      IDP_PROJECT_IDENTIFIER,
      privateApiKey
    );

    const apiAccessToken = await idpClient.generateAccessToken();

    const apiClient = new ApiClient(FORM_ID, API_URL, apiAccessToken);

    const tests: ApiTest[] = [
      new CommonUseCaseTest(submissionGenerator, apiClient, privateApiKey),
      new RateLimiterTest(apiClient),
    ];

    for (const test of tests) {
      console.info(`>>> Running ${test.name}...`);

      await test.run();

      console.info(`<<< ${test.name} completed!`);
    }
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run API end to end test",
        error: (error as Error).message,
      })
    );

    throw error;
  }
};
