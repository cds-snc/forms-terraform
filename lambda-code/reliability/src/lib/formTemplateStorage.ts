import { prisma } from "@gcforms/database";
import type { FormProperties } from "@gcforms/types";
import { EitherAsync, Just, type Maybe, Nothing } from "purify-ts";

export type FormTemplate = {
  formConfig: FormProperties;
  deliveryOption?: {
    emailAddress: string;
    emailSubjectEn: string | null;
    emailSubjectFr: string | null;
  };
  isFormArchived: boolean;
};

export function retrieveFormTemplate(id: string): EitherAsync<Error, Maybe<FormTemplate>> {
  return EitherAsync(() =>
    prisma.template.findUnique({
      where: {
        id,
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
    }),
  )
    .map((result) => {
      if (result === null) {
        return Nothing;
      }

      return Just({
        formConfig: result.jsonConfig as FormProperties,
        ...(result.deliveryOption && { deliveryOption: result.deliveryOption }),
        isFormArchived: result.ttl !== null,
      } satisfies FormTemplate);
    })
    .mapLeft((error) => new Error("Failed to retrieve form template", { cause: error }));
}
