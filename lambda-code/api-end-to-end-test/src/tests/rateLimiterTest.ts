import { ApiClient } from "@lib/apiClient.js";
import { pause } from "@lib/utils.js";

const DEFAULT_API_RATE_LIMIT_TOKEN_BUCKET_CAPACITY = 500;
const DEFAULT_API_RATE_LIMIT_TOKEN_BUCKET_REFILL_DURATION_IN_SECONDS = 60;

export class RateLimiterTest implements ApiTest {
  public name = "RateLimiterTest";

  private apiClient: ApiClient;

  public constructor(apiClient: ApiClient) {
    this.apiClient = apiClient;
  }

  public async run(): Promise<void> {
    console.info(
      `Waiting for ${DEFAULT_API_RATE_LIMIT_TOKEN_BUCKET_REFILL_DURATION_IN_SECONDS} seconds to let the API rate limiter refill the bucket`
    );

    await pause(DEFAULT_API_RATE_LIMIT_TOKEN_BUCKET_REFILL_DURATION_IN_SECONDS);

    console.info("Sending initial request...");

    const initialRateLimitStatus = (await this.apiClient.getNewFormSubmissions()).rateLimitStatus;

    if (initialRateLimitStatus.limit !== DEFAULT_API_RATE_LIMIT_TOKEN_BUCKET_CAPACITY) {
      throw new Error(
        `Invalid API rate limit token bucket capacity. Actual limit ${initialRateLimitStatus.limit} / Expected ${DEFAULT_API_RATE_LIMIT_TOKEN_BUCKET_CAPACITY}`
      );
    }

    console.info(
      `Sending ${initialRateLimitStatus.remanining} more requests to force rate limiter to block final request...`
    );

    for (let i = 0; i < initialRateLimitStatus.remanining; i++) {
      const apiResponse = await this.apiClient.getNewFormSubmissions();

      if (apiResponse.status === 429) {
        throw new Error("API rate limiter blocked request that should have been allowed");
      }
    }

    console.info("Sending final request...");

    const finalApiOperation = await this.apiClient.getNewFormSubmissions();

    if (finalApiOperation.status !== 429) {
      throw new Error("API rate limiter allowed request that should have been blocked");
    }

    if (finalApiOperation.rateLimitStatus.retryAfter === undefined) {
      throw new Error("API rate limit status is missing Retry-After HTTP header");
    }
  }
}
