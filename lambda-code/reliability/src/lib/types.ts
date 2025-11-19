import { Responses, DeliveryOption, FormProperties } from "@gcforms/types";

export type FormSubmission = {
  form: FormProperties;
  responses: Responses;
  deliveryOption: DeliveryOption;
};
