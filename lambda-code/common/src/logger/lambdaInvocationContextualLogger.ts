import { Logger } from "@aws-lambda-powertools/logger";
import type { Context } from "aws-lambda";
import { LambdaInvocationContextualLogFormatter } from "./lambdaInvocationContextualLogFormatter.ts";

export interface LambdaInvocationContextualLogger {
  addMetadata(key: string, value: string): void;
  log(log: Log): void;
}

type Log =
  | { level: "info"; message: string }
  | { level: "warn"; message: string }
  | {
      level: "error";
      message: string;
      error: Error;
      severityLevel?: "1" | "2";
    };

export class DefaultLambdaInvocationContextualLogger implements LambdaInvocationContextualLogger {
  private readonly logger: Logger;

  public static createWithDefaultLogFormatter(): DefaultLambdaInvocationContextualLogger {
    return new DefaultLambdaInvocationContextualLogger(
      new Logger({
        logFormatter: new LambdaInvocationContextualLogFormatter(),
      }),
    );
  }

  protected constructor(logger: Logger) {
    this.logger = logger;
  }

  public startInvocationContext(context: Context): void {
    this.logger.addContext(context);
  }

  public endInvocationContext(): void {
    this.logger.resetKeys();
  }

  public addMetadata(key: string, value: string): void {
    this.logger.appendKeys({ [key]: value });
  }

  public log(log: Log): void {
    switch (log.level) {
      case "info":
        this.logger.info(log.message);
        break;
      case "warn":
        this.logger.warn(log.message);
        break;
      case "error":
        this.logger.error(log.message, {
          error: log.error,
          severityLevel: log.severityLevel,
        });
        break;
    }
  }
}
