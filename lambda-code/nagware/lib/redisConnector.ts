import { type RedisClientType, createClient } from "redis";

const REDIS_URL = process.env.REDIS_URL ?? "redis://localhost:6379";

export class RedisConnector {
  private static instance: RedisConnector | undefined = undefined;
  private static RETRY_MAX = 10;
  private static RETRY_DELAY_STEP = 500; // milliseconds

  public client: RedisClientType;

  private constructor() {
    this.client = createClient({
      url: REDIS_URL,
      socket: {
        // Reconnect strategy with exponential backoff
        reconnectStrategy: (retries: number): number | Error =>
          retries < RedisConnector.RETRY_MAX
            ? RedisConnector.RETRY_DELAY_STEP * retries
            : new Error("Failed to connect to Redis"),
      },
    });
    this.client
      .on("error", (err: Error) => console.error("Redis client error:", err))
      .on("ready", () => console.log("Redis client ready!"))
      .on("reconnecting", () => console.log("Redis client reconnecting..."));
  }

  /**
   * Uses the singleton promise pattern to initialize the RedisConnector class instance.
   * This ensures that only one connection is attempted to the Redis server when the
   * instance is first initialized, even if multiple concurrent calls are made.
   * @returns {Promise<RedisConnector>}
   */
  public static async getInstance(): Promise<RedisConnector> {
    if (RedisConnector.instance === undefined) {
      RedisConnector.instance = new RedisConnector();
      await RedisConnector.instance.client.connect();
    }
    return RedisConnector.instance;
  }
}