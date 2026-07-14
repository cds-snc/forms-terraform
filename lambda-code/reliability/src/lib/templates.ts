import { FormProperties } from "@gcforms/types";
import { prisma } from "@gcforms/database";

export type TemplateInfo = {
  formConfig: FormProperties;
  deliveryOption?: {
    emailAddress: string;
    emailSubjectEn: string | null;
    emailSubjectFr: string | null;
  };
  isFormArchived: boolean;
};

export async function getTemplateInfo(formID: string): Promise<TemplateInfo | null> {
  try {
    const template = await prisma.template.findUnique({
      where: {
        id: formID,
        ttl: { not: undefined }, // Because the database package adds a default filter on TTL (if none specified) we want to make sure we can also retrieve archived templates
      },
      select: {
        jsonConfig: true,
        deliveryOption: {
          select: {
            emailAddress: true,
            emailSubjectEn: true,
            emailSubjectFr: true,
          },
        },
        ttl: true,
      },
    });

    if (template === null) {
      return null;
    }

    return {
      formConfig: template.jsonConfig as FormProperties,
      ...(template.deliveryOption && { deliveryOption: template.deliveryOption }),
      isFormArchived: template.ttl !== null ? true : false,
    };
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
