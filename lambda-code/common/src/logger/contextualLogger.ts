import { Logger } from "@aws-lambda-powertools/logger";
import type { Context } from "aws-lambda";
import { ContextualLogFormatter } from "./contextualLogFormatter.ts";

export interface ContextualLogger {
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

export class DefaultContextualLogger implements ContextualLogger {
  private readonly logger: Logger;

  constructor() {
    this.logger = new Logger({
      logFormatter: new ContextualLogFormatter(),
    });
  }

  addContext(context: Context): void {
    this.logger.addContext(context);
  }

  addMetadata(key: string, value: string): void {
    this.logger.appendKeys({ [key]: value });
  }

  log(log: Log): void {
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
