import { vi } from "vitest";

export const contextualLoggerMock = {
  startInvocationContext: vi.fn(),
  endInvocationContext: vi.fn(),
  createChildLogger: vi.fn(),
  addMetadata: vi.fn(),
  log: vi.fn(),
};

vi.mock("./lambda-code/common/src/logger/lambdaInvocationContextualLogger.ts", () => ({
  DefaultLambdaInvocationContextualLogger: {
    createWithDefaultLogFormatter: vi.fn(() => contextualLoggerMock),
  },
}));