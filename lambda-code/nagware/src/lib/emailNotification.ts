import { GCNotifyConnector } from "@gcforms/connectors";

const gcNotifyConnector = await GCNotifyConnector.defaultUsingApiKeyFromAwsSecret(
  process.env.NOTIFY_API_KEY ?? ""
);

export async function notifyFormOwner(
  formID: string,
  formName: string,
  formOwnerEmailAddress: string
) {
  try {
    const templateId = process.env.TEMPLATE_ID;

    if (templateId === undefined) {
      throw new Error(`Missing Environment Variables: ${templateId ? "" : "Template ID"}`);
    }

    const baseUrl = `http://${process.env.DOMAIN}`;

    await gcNotifyConnector.sendEmail(formOwnerEmailAddress, templateId, {
      subject: "Action required: Overdue responses | Action requise : Réponses non traitées",
      formResponse: `      

You have responses waiting on your form:

**${formName}**

Promptly downloading responses is important to protect the personal information of people who filled out your form. 

Restrictions will be applied to your account, if responses are in GC Forms for more than 35 days.

[Retrieve form response data](${baseUrl}/form-builder/${formID}/responses)

****

Vous avez des réponses en attente sur votre formulaire : 

**${formName}**

Il est important de télécharger rapidement les réponses afin de protéger les informations personnelles des personnes qui ont rempli à votre formulaire. 

Des restrictions seront appliquées à votre compte si les réponses datent de plus de 35 jours.

[Récupérer les réponses de Formulaires GC](${baseUrl}/fr/form-builder/${formID}/responses)`,
    });
  } catch (error) {
    // Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        msg: `Failed to send nagware email to form owner: ${formOwnerEmailAddress} for form ID ${formID} .`,
        error: (error as Error).message,
      })
    );

    // Continue to send nagware emails even if one fails
    return;
  }
}
