import type { BatchStatementResponse } from "@aws-sdk/client-dynamodb";
import { BatchExecuteStatementCommand, DynamoDBDocument, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { mockClient } from "aws-sdk-client-mock";
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { confirmOverdueResponses, retrieveNextBatchOfOverdueResponses } from "../../src/lib/vault.ts";

const dynamodbMock = mockClient(DynamoDBDocument);

const NOW_TIMESTAMP_MOCK = new Date("2026-11-23T12:00:00.000Z").getTime();
const DAY_IN_MS = 24 * 60 * 60 * 1000;
const THIRTY_DAYS_IN_MS = 30 * DAY_IN_MS;

describe("vault", () => {
  beforeAll(() => {
    vi.stubEnv("DYNAMODB_VAULT_TABLE_NAME", "dynamodb_table_name");
    vi.stubEnv("DYNAMODB_VAULT_STATUS_CREATED_AT_V2_INDEX_NAME", "dynamodb_index_name");
  });

  beforeEach(() => {
    vi.setSystemTime(NOW_TIMESTAMP_MOCK);
  });

  afterEach(() => {
    dynamodbMock.reset();
  });

  describe("retrieveOverdueResponses", () => {
    it("retrieves overdue responses using the expected query parameters", async () => {
      const ageInDays = 45;
      const createdAt = NOW_TIMESTAMP_MOCK - 60 * DAY_IN_MS;

      dynamodbMock.on(QueryCommand).resolves({
        Items: [
          { Name: "response-1", CreatedAt: createdAt },
          { Name: "response-2", CreatedAt: createdAt + 1000 },
        ],
      });

      const result = await retrieveNextBatchOfOverdueResponses("tz4a98xxat96iws9zmbrgj3a", ageInDays).run();

      expect(result.extract()).toEqual({
        overdueResponses: [
          { name: "response-1", createdAt },
          { name: "response-2", createdAt: createdAt + 1000 },
        ],
        lastEvaluatedKey: undefined,
      });

      expect(dynamodbMock.commandCalls(QueryCommand).length).toEqual(1);
      expect(dynamodbMock.commandCalls(QueryCommand)[0].args[0].input).toEqual({
        TableName: "dynamodb_table_name",
        IndexName: "dynamodb_index_name",
        ExclusiveStartKey: undefined,
        Limit: 25,
        KeyConditionExpression: "FormID = :formId AND #statusCreatedAtKey BETWEEN :lowerBound AND :upperBound",
        ProjectionExpression: "#name,CreatedAt",
        ExpressionAttributeNames: {
          "#statusCreatedAtKey": "Status#CreatedAt",
          "#name": "Name",
        },
        ExpressionAttributeValues: {
          ":formId": "tz4a98xxat96iws9zmbrgj3a",
          ":lowerBound": "Downloaded#0000000000000",
          ":upperBound": `Downloaded#${NOW_TIMESTAMP_MOCK - ageInDays * DAY_IN_MS}`,
        },
      });
    });

    it("passes the last evaluated key to DynamoDB when provided", async () => {
      const lastEvaluatedKey = {
        FormID: "tz4a98xxat96iws9zmbrgj3a",
        "Status#CreatedAt": "Downloaded#1795000000000",
      };

      dynamodbMock.on(QueryCommand).resolves({ Items: [] });

      await retrieveNextBatchOfOverdueResponses("tz4a98xxat96iws9zmbrgj3a", 45, lastEvaluatedKey).run();

      expect(dynamodbMock.commandCalls(QueryCommand).length).toEqual(1);
      expect(dynamodbMock.commandCalls(QueryCommand)[0].args[0].input).toMatchObject({
        ExclusiveStartKey: lastEvaluatedKey,
      });
    });

    it("returns an empty array when DynamoDB does not return any items", async () => {
      dynamodbMock.on(QueryCommand).resolves({});

      const result = await retrieveNextBatchOfOverdueResponses("tz4a98xxat96iws9zmbrgj3a", 45).run();

      expect(result.extract()).toEqual({
        overdueResponses: [],
        lastEvaluatedKey: undefined,
      });
    });

    it("returns an empty array when DynamoDB returns an empty Items array", async () => {
      dynamodbMock.on(QueryCommand).resolves({ Items: [] });

      const result = await retrieveNextBatchOfOverdueResponses("tz4a98xxat96iws9zmbrgj3a", 45).run();

      expect(result.extract()).toEqual({
        overdueResponses: [],
        lastEvaluatedKey: undefined,
      });
    });

    it("maps the DynamoDB error to an Error", async () => {
      const dynamodbError = new Error("DynamoDB is unavailable");

      dynamodbMock.on(QueryCommand).rejects(dynamodbError);

      const result = await retrieveNextBatchOfOverdueResponses("tz4a98xxat96iws9zmbrgj3a", 45).run();

      expect(result.extract()).toEqual(new Error("Failed to retrieve overdue responses", { cause: dynamodbError }));
    });
  });

  describe("confirmOverdueResponses", () => {
    it("does not execute a batch when there are no overdue responses", async () => {
      const result = await confirmOverdueResponses("tz4a98xxat96iws9zmbrgj3a", []).run();

      expect(result.isRight()).toBe(true);
      expect(dynamodbMock.commandCalls(BatchExecuteStatementCommand).length).toEqual(0);
    });

    it("returns a Left when more than 25 overdue responses are provided", async () => {
      const result = await confirmOverdueResponses(
        "tz4a98xxat96iws9zmbrgj3a",
        Array.from({ length: 26 }, (_, index) => ({ name: `response-${index + 1}`, createdAt: NOW_TIMESTAMP_MOCK - 60 * DAY_IN_MS })),
      ).run();

      expect(result.extract()).toEqual(new Error("This version of the code cannot confirm more than 25 overdue responses at a time (BatchExecuteStatementCommand)"));
      expect(dynamodbMock.commandCalls(BatchExecuteStatementCommand).length).toEqual(0);
    });

    it("confirms overdue responses using one PartiQL statement per response", async () => {
      const createdAt1 = NOW_TIMESTAMP_MOCK - 60 * DAY_IN_MS;
      const createdAt2 = NOW_TIMESTAMP_MOCK - 50 * DAY_IN_MS;

      const overdueResponses = [
        { name: "response-1", createdAt: createdAt1 },
        { name: "response-2", createdAt: createdAt2 },
      ];

      dynamodbMock.on(BatchExecuteStatementCommand).resolves({
        $metadata: { httpStatusCode: 200 },
        Responses: [],
      });

      const result = await confirmOverdueResponses("tz4a98xxat96iws9zmbrgj3a", overdueResponses).run();

      expect(result.isRight()).toBe(true);

      expect(dynamodbMock.commandCalls(BatchExecuteStatementCommand).length).toEqual(1);
      expect(dynamodbMock.commandCalls(BatchExecuteStatementCommand)[0].args[0].input).toMatchObject({
        Statements: overdueResponses.map((response) => ({
          Statement: `UPDATE "dynamodb_table_name" SET "Status#CreatedAt" = ?, "ConfirmTimestamp" = ?, "RemovalDate" = ? WHERE "FormID" = ? AND "NAME_OR_CONF" = ?`,
          Parameters: [`Confirmed#${response.createdAt}`, NOW_TIMESTAMP_MOCK, NOW_TIMESTAMP_MOCK + THIRTY_DAYS_IN_MS, "tz4a98xxat96iws9zmbrgj3a", `NAME#${response.name}`],
        })),
      });
    });

    it("successfully confirms exactly 25 overdue responses", async () => {
      dynamodbMock.on(BatchExecuteStatementCommand).resolves({
        $metadata: { httpStatusCode: 200 },
        Responses: [],
      });

      const result = await confirmOverdueResponses(
        "tz4a98xxat96iws9zmbrgj3a",
        Array.from({ length: 25 }, (_, index) => ({ name: `response-${index + 1}`, createdAt: NOW_TIMESTAMP_MOCK - 60 * DAY_IN_MS })),
      ).run();

      expect(result.isRight()).toBe(true);

      expect(dynamodbMock.commandCalls(BatchExecuteStatementCommand).length).toEqual(1);
      expect(dynamodbMock.commandCalls(BatchExecuteStatementCommand)[0].args[0].input).toMatchObject({
        Statements: expect.arrayContaining([
          expect.objectContaining({
            Parameters: expect.arrayContaining(["tz4a98xxat96iws9zmbrgj3a"]),
          }),
        ]),
      });
    });

    it("returns a Left when the batch HTTP status code is not 200", async () => {
      dynamodbMock.on(BatchExecuteStatementCommand).resolves({
        $metadata: { httpStatusCode: 500 },
        Responses: [],
      });

      const result = await confirmOverdueResponses("tz4a98xxat96iws9zmbrgj3a", [{ name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 60 * DAY_IN_MS }]).run();

      expect(result.extract()).toEqual(new Error("Failed to confirm overdue responses", { cause: new Error("At least one update statement in the batch did not succeed") }));
    });

    it("returns a Left when at least one PartiQL statement fails", async () => {
      const statementError: BatchStatementResponse = {
        Error: {
          Code: "ConditionalCheckFailed",
          Message: "The condition was not met",
        },
      };

      dynamodbMock.on(BatchExecuteStatementCommand).resolves({
        $metadata: { httpStatusCode: 200 },
        Responses: [statementError],
      });

      const result = await confirmOverdueResponses("tz4a98xxat96iws9zmbrgj3a", [{ name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 60 * DAY_IN_MS }]).run();

      expect(result.extract()).toEqual(
        new Error("Failed to confirm overdue responses", {
          cause: new Error("At least one update statement in the batch did not succeed", { cause: JSON.stringify([statementError]) }),
        }),
      );
    });

    it("maps the DynamoDB error to an Error", async () => {
      const dynamodbError = new Error("DynamoDB is unavailable");

      dynamodbMock.on(BatchExecuteStatementCommand).rejects(dynamodbError);

      const result = await confirmOverdueResponses("tz4a98xxat96iws9zmbrgj3a", [{ name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 60 * DAY_IN_MS }]).run();

      expect(result.extract()).toEqual(new Error("Failed to confirm overdue responses", { cause: dynamodbError }));
    });
  });
});
