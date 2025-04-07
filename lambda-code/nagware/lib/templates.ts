import { PostgresConnector } from "@gcforms/connectors";

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
    const postgresConnector =
      await PostgresConnector.defaultUsingPostgresConnectionUrlFromAwsSecret(
        process.env.DB_URL ?? ""
      );

    const result = await postgresConnector.executeSqlStatement()<
      {
        user_name?: string;
        email: string;
        template_name: string;
        jsonConfig: Record<string, unknown>;
        isPublished: boolean;
      }[]
    >`SELECT usr."name" AS user_name, usr."email", tem."name" AS template_name, tem."jsonConfig", tem."isPublished"
      FROM "User" usr
      JOIN "_TemplateToUser" ttu ON usr."id" = ttu."B"
      JOIN "Template" tem ON tem."id" = ttu."A"
      WHERE ttu."A" = ${formID}`;

    if (result.length > 0) {
      const { template_name, jsonConfig, isPublished } = result[0];

      // Even if we type the result we expect from our Postgres.js request, the properties could still be undefined if they don't exist in the database.
      if (template_name === undefined || jsonConfig === undefined || isPublished === undefined) {
        throw new Error(
          `Missing required parameters: template name = ${template_name} ; template jsonConfig = ${jsonConfig} ; template isPublished = ${isPublished}.`
        );
      }

      // Note we use || instead of ?? to allow for empty strings
      const formName = template_name || `${jsonConfig.titleEn} - ${jsonConfig.titleFr}`;

      const owners = result.map((record) => {
        // make sure owner email is defined
        if (!record.email) {
          throw new Error(`Missing required parameters: owner email.`);
        }

        return { name: record.user_name, email: record.email };
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
