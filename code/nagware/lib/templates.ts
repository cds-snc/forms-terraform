import { RDSDataClient, ExecuteStatementCommand } from "@aws-sdk/client-rds-data";

export type TemplateInfo = {
  formName: string;
  owners: {
    name: string | undefined;
    email: string;
  }[];
  isPublished: boolean;
};

export async function getTemplateInfo(formID: string): Promise<TemplateInfo> {
  try {
    const rdsDataClient = new RDSDataClient({ region: process.env.REGION });

    // Due to Localstack limitations we have to define aliases for fields that have the same name
    const sqlStatement = `
      SELECT usr."name" AS user_name, usr."email", tem."name" AS template_name, tem."jsonConfig", tem."isPublished"
      FROM "User" usr
      JOIN "_TemplateToUser" ttu ON usr."id" = ttu."B"
      JOIN "Template" tem ON tem."id" = ttu."A"
      WHERE ttu."A" = :formID
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

    if (response.records && response.records.length > 0) {
      const firstRecord = response.records[0];

      if (
        firstRecord[2].stringValue === undefined || // template name
        firstRecord[3].stringValue === undefined || // template jsonConfig
        firstRecord[4].booleanValue === undefined // template isPublished
      ) {
        throw new Error(
          `Missing required parameters: template name = ${firstRecord[2].stringValue} ; template jsonConfig = ${firstRecord[3].stringValue} ; template isPublished = ${firstRecord[4].stringValue}.`
        );
      }

      const jsonConfig = JSON.parse(firstRecord[3].stringValue.trim());

      const formName =
        firstRecord[2].stringValue !== ""
          ? firstRecord[2].stringValue
          : `${jsonConfig.titleEn} - ${jsonConfig.titleFr}`;

      const isPublished = firstRecord[4].booleanValue;

      const owners = response.records.map((record) => {
        // make sure owner email is defined
        if (record[1].stringValue === undefined) {
          throw new Error(`Missing required parameters: owner email.`);
        }

        return { name: record[0].stringValue, email: record[1].stringValue };
      });

      return { formName, owners, isPublished };
    } else {
      throw new Error(`Could not find any template with form identifier: ${formID}.`);
    }
  } catch (error) {
    console.error(
      JSON.stringify({
        status: "error",
        error: (error as Error).message,
      })
    );
    throw new Error(
      `Failed to retrieve template information. Reason: ${(error as Error).message}.`
    );
  }
}
