import { prisma } from "@gcforms/database";
import { FormProperties } from "@gcforms/types";

export type TemplateInfo = {
  formName: string;
  owners: {
    name: string | null;
    email: string;
  }[];
  isPublished: boolean;
};

export async function getTemplateInfo(formID: string): Promise<TemplateInfo> {
  try {
    const template = await prisma.template.findUnique({
      where: {
        id: formID,
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
      },
    });

    if (template === null) {
      throw new Error(`Could not find any template with form identifier: ${formID}.`);
    }

    const formProperties = template.jsonConfig as FormProperties;

    // Note we use || instead of ?? to allow for empty strings
    const formName = template.name || `${formProperties.titleEn} - ${formProperties.titleFr}`;

    return { formName, owners: template.users, isPublished: template.isPublished };
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
