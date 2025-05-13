import { RedisConnector } from "./redisConnector.js";

/**
 * Handles caching of overdue form responses.  The cache expiry should be at least
 * as long as the interval between Nagware function runs.
 *
 * This cache is used by the app to reduce the number of DynamoDB calls required
 * when loading the user's `/forms` page.
 */

const OVERDUE_CACHE_EXPIRE_SECONDS = 86400; // 1 day
const OVERDUE_CACHE_KEY = "overdue:responses:template-ids";

export async function setOverdueResponseCache(
  formResponses: { formID: string; createdAt: number }[]
): Promise<void> {
  const formIDs = formResponses.map((formResponse) => formResponse.formID);
  const redisConnector = await RedisConnector.getInstance();
  await redisConnector.client.set(OVERDUE_CACHE_KEY, JSON.stringify(formIDs), {
    EX: OVERDUE_CACHE_EXPIRE_SECONDS,
  });
}
