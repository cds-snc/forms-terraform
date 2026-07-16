import { prisma } from "@gcforms/database";
import { FormProperties } from "@gcforms/types";

export type TemplateInfo = {
  formName: string;
  owners: {
    name: string | null;
    email: string;
  }[];
  isPublished: boolean;
  isFormArchived: boolean;
};

export async function getTemplateInfo(formID: string): Promise<TemplateInfo> {
  try {
    const template = await prisma.template.findUnique({
      where: {
        id: formID,
        ttl: { not: undefined }, // Because the database package adds a default filter on TTL (if none specified) we want to make sure we can also retrieve archived templates
      },
      select: {
        name: true,
        jsonConfig: true,
        isPublished: true,
        users: {
          select: {
            name: true,
            email: true,
          },
        },
        ttl: true,
      },
    });

    if (template === null) {
      throw new Error(`Could not find any template with form identifier: ${formID}.`);
    }

    const formProperties = template.jsonConfig as FormProperties;

    // Note we use || instead of ?? to allow for empty strings
    const formName = template.name || `${formProperties.titleEn} - ${formProperties.titleFr}`;

    return {
      formName,
      owners: template.users,
      isPublished: template.isPublished,
      isFormArchived: template.ttl !== null ? true : false,
    };
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
