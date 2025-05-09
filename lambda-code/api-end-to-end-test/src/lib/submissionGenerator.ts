import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { InvokeCommand, LambdaClient } from "@aws-sdk/client-lambda";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { pause } from "@lib/utils.js";

export class SubmissionGenerator {
  private formId: string;
  private lambdaClient: LambdaClient;
  private dynamodbClient: DynamoDBDocumentClient;

  public constructor(formId: string) {
    this.formId = formId;

    this.lambdaClient = new LambdaClient({
      region: "ca-central-1",
      retryMode: "standard",
    });

    this.dynamodbClient = DynamoDBDocumentClient.from(
      new DynamoDBClient({ region: "ca-central-1", maxAttempts: 15 })
    );
  }

  public generateSubmission(responses: Record<string, string>): Promise<string> {
    return this.lambdaClient
      .send(
        new InvokeCommand({
          FunctionName: "Submission",
          Payload: JSON.stringify({
            formID: this.formId,
            language: "en",
            responses,
          }),
        })
      )
      .then((invokeCommandOutput) => pause(8).then((_) => invokeCommandOutput))
      .then((invokeCommandOutput) =>
        this.retrieveSubmissionNameOnceAvailable(
          JSON.parse(invokeCommandOutput.Payload?.transformToString() ?? "{}").submissionId
        )
      );
  }

  private async retrieveSubmissionNameOnceAvailable(submissionId: string): Promise<string> {
    while (true) {
      const result = await this.dynamodbClient.send(
        new QueryCommand({
          TableName: "Vault",
          KeyConditionExpression:
            "FormID = :formId AND begins_with(NAME_OR_CONF, :nameOrConfPrefix)",
          FilterExpression: "SubmissionID = :submissionId",
          ProjectionExpression: "#name",
          ExpressionAttributeNames: {
            "#name": "Name",
          },
          ExpressionAttributeValues: {
            ":formId": this.formId,
            ":nameOrConfPrefix": "NAME#",
            ":submissionId": submissionId,
          },
        })
      );

      if (result.Items && result.Items.length > 0) {
        return result.Items[0].Name;
      }

      await pause(5);
    }
  }
}
