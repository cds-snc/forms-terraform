import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";

const region = process.env.REGION ?? "ca-central-1";

export const dynamodbClient = DynamoDBDocument.from(new DynamoDBClient({ region }));
