import { RDSDataClient, ExecuteStatementCommand } from "@aws-sdk/client-rds-data";
import { FormProperties } from "./types.js";

export type TemplateInfo = {
  formConfig: FormProperties;
  deliveryOption?: {
    emailAddress: string;
    emailSubjectEn: string | undefined;
    emailSubjectFr: string | undefined;
  };
};

export async function getTemplateInfo(formID: string): Promise<TemplateInfo | null> {
  try {
    const rdsDataClient = new RDSDataClient({ region: process.env.REGION });

    const sqlStatement = `
      SELECT  t."jsonConfig", deli."emailAddress", deli."emailSubjectEn", deli."emailSubjectFr"
      FROM "Template" t
      LEFT JOIN "DeliveryOption" deli ON t.id = deli."templateId"
      WHERE t.id = :formID
    `;

    const executeStatementCommand = new ExecuteStatementCommand({
      database: process.env.DB_NAME,
      resourceArn: process.env.DB_ARN,
      secretArn: process.env.DB_SECRET,
      sql: sqlStatement,
      includeResultMetadata: false, // set to true if we want metadata like column names
      parameters: [
        {
          name: "formID",
          value: {
            stringValue: formID,
          },
        },
      ],
    });

    const response = await rdsDataClient.send(executeStatementCommand);

    if (response.records && response.records.length === 1) {
      const firstRecord = response.records[0];

      // make sure template jsonConfig is defined
      if (firstRecord[0].stringValue === undefined) {
        throw new Error(`Missing required parameters: template jsonConfig.`);
      }

      const formConfig = JSON.parse(firstRecord[0].stringValue!.trim()) as FormProperties;

      const deliveryOption = firstRecord[1].stringValue
        ? {
            emailAddress: firstRecord[1].stringValue,
            emailSubjectEn: firstRecord[2].stringValue,
            emailSubjectFr: firstRecord[3].stringValue,
          }
        : null;

      return {
        formConfig,
        ...(deliveryOption && { deliveryOption }),
      };
    } else {
      return null;
    }
  } catch (error) {
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: "Failed to retrieve template form config from DB",
        error: (error as Error).message,
      })
    );

    // Return as if no template with ID was found.
    // Handle error in calling function if template is not found.
    return null;
  }
}
