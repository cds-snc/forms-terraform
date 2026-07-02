import { EmailContent } from "@gcforms/connectors";

export type Notification = {
  id: string;
  emailRecipients: string[];
  emailContent: EmailContent;
};
