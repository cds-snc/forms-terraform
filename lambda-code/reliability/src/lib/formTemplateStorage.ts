import { prisma } from "@gcforms/database";
import type { FormProperties } from "@gcforms/types";
import { EitherAsync, Just, type Maybe, Nothing } from "purify-ts";

export type Email = { address: string; subjectEn?: string; subjectFr?: string };

export type DeliveryMethod = { type: "vault" } | { type: "email"; email: Email };

export type Form = {
  template: FormProperties;
  deliveryMethod: DeliveryMethod;
  isArchived: boolean;
};

export function retrieveForm(id: string): EitherAsync<Error, Maybe<Form>> {
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
        template: result.jsonConfig as FormProperties,
        deliveryMethod:
          result.deliveryOption === null
            ? { type: "vault" }
            : {
                type: "email",
                email: {
                  address: result.deliveryOption.emailAddress,
                  subjectEn: result.deliveryOption.emailSubjectEn ?? undefined,
                  subjectFr: result.deliveryOption.emailSubjectFr ?? undefined,
                },
              },
        isArchived: result.ttl !== null,
      } satisfies Form);
    })
    .mapLeft((error) => new Error("Failed to retrieve form template", { cause: error }));
}
