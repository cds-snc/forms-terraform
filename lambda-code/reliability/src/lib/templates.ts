import { FormProperties } from "./types.js";
import { PostgresConnector } from "@gcforms/connectors";

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
    const postgresConnector =
      await PostgresConnector.defaultUsingPostgresConnectionUrlFromAwsSecret(
        process.env.DB_URL ?? ""
      );

    const templates = await postgresConnector.executeSqlStatement()<
      {
        jsonConfig?: Record<string, unknown>;
        emailAddress?: string;
        emailSubjectEn?: string;
        emailSubjectFr?: string;
      }[]
    >`SELECT  t."jsonConfig", deli."emailAddress", deli."emailSubjectEn", deli."emailSubjectFr"
      FROM "Template" t
      LEFT JOIN "DeliveryOption" deli ON t.id = deli."templateId"
      WHERE t.id = ${formID}`;

    if (templates.length === 1) {
      const { jsonConfig, emailAddress, emailSubjectEn, emailSubjectFr } = templates[0];

      // make sure template jsonConfig is defined
      if (jsonConfig === undefined) {
        throw new Error(`Missing required parameters: template jsonConfig.`);
      }

      const formConfig = jsonConfig as FormProperties;

      const deliveryOption = emailAddress
        ? {
            emailAddress,
            emailSubjectEn,
            emailSubjectFr,
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
