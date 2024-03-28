export type FormSubmission = {
  form: FormProperties;
  responses: Responses;
  deliveryOption: DeliveryOption;
};

export type Responses = {
  [key: string]: Response;
};

export type Response =
  | string
  | string[]
  | number
  | Record<string, unknown>[]
  | FileInputResponse
  | FileInputResponse[]
  | Record<string, unknown>;

export type FileInputResponse = {
  name: string;
  file: string;
  [key: string]: string | number;
};

// the choices available for fields with multiple options like dropdowns or radio buttons
export interface PropertyChoices {
  en: string;
  fr: string;
  [key: string]: string;
}

// used to define attributes for the properties of an element in the form
export interface ElementProperties {
  titleEn: string;
  titleFr: string;
  placeholderEn?: string;
  placeholderFr?: string;
  descriptionEn?: string;
  descriptionFr?: string;
  choices?: PropertyChoices[];
  subElements?: FormElement[];
  fileType?: string | undefined;
  headingLevel?: string | undefined;
  isSectional?: boolean;
  maxNumberOfRows?: number;
  autoComplete?: string;
  [key: string]:
    | string
    | number
    | boolean
    | Array<PropertyChoices>
    | Array<FormElement>
    | undefined;
}

// all the possible types of form elements
export enum FormElementTypes {
  textField = "textField",
  textArea = "textArea",
  dropdown = "dropdown",
  combobox = "combobox",
  radio = "radio",
  checkbox = "checkbox",
  fileInput = "fileInput",
  richText = "richText",
  dynamicRow = "dynamicRow",
  attestation = "attestation",
  address = "address",
  name = "name",
  firstMiddleLastName = "firstMiddleLastName",
  contact = "contact",
}
// used to define attributes for a form element or field
export interface FormElement {
  id: number;
  subId?: string;
  type: FormElementTypes;
  properties: ElementProperties;
  brand?: BrandProperties;
}

/**
 * types to define form configuration objects
 */

// defines the fields in the object that controls form branding
export interface BrandProperties {
  name?: string;
  logoEn: string;
  logoFr: string;
  logoTitleEn: string;
  logoTitleFr: string;
  urlEn?: string;
  urlFr?: string;
  // if set to true the GC branding will be removed from the footer
  disableGcBranding?: boolean;
  [key: string]: string | boolean | undefined;
}

// defines the fields for the main form configuration object
export interface FormProperties {
  titleEn: string;
  titleFr: string;
  introduction?: Record<string, string>;
  privacyPolicy?: Record<string, string>;
  confirmation?: Record<string, string>;
  closedMessage?: Record<string, string>;
  layout: number[];
  elements: FormElement[];
  brand?: BrandProperties;
  [key: string]:
    | string
    | number
    | boolean
    | Array<string | number | FormElement>
    | Record<string, string>
    | BrandProperties
    | undefined;
}

// defines the fields in the object that controls how form submissions are delivered
export interface DeliveryOption {
  emailAddress: string;
  emailSubjectEn?: string;
  emailSubjectFr?: string;
  [key: string]: string | undefined;
}

export type SecurityAttribute = "Unclassified" | "Protected A" | "Protected B";
