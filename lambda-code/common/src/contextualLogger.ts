import { AsyncLocalStorage } from "node:async_hooks";

export class ContextualLogger {
  private readonly asyncLocalStorage: AsyncLocalStorage<Map<string, string>>;

  constructor(asyncLocalStorage: AsyncLocalStorage<Map<string, string>>) {
    this.asyncLocalStorage = asyncLocalStorage;
  }

  static use<T>(callback: (contextualLogger: ContextualLogger) => T): T {
    const asyncLocalStorage = new AsyncLocalStorage<Map<string, string>>();
    const contextualLogger = new ContextualLogger(asyncLocalStorage);
    return asyncLocalStorage.run(new Map(), () => callback(contextualLogger));
  }
}
