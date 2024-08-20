import axios, { type AxiosInstance } from "axios";

export type Personalisation = Record<string, string | boolean | Record<string, string | boolean>>;

export class GCNotifyClient {
  private axiosInstance: AxiosInstance;

  public static default(apiKey: string, timeout: number = 2000): GCNotifyClient {
    return new GCNotifyClient("https://api.notification.canada.ca", apiKey, timeout);
  }

  private constructor(apiUrl: string, apiKey: string, timeout: number) {
    this.axiosInstance = axios.create({
      baseURL: apiUrl,
      timeout: timeout,
      headers: {
        "Content-Type": "application/json",
        Authorization: `ApiKey-v1 ${apiKey}`,
      },
    });
  }

  public async sendEmail(
    emailAddress: string,
    templateId: string,
    personalisation: Personalisation,
    reference?: string
  ): Promise<void> {
    try {
      await this.axiosInstance.post("/v2/notifications/email", {
        email_address: emailAddress,
        template_id: templateId,
        personalisation,
        ...(reference && { reference }),
      });
    } catch (error) {
      let errorMessage = "";
      if (axios.isAxiosError(error)) {
        if (error.response) {
          /*
           * The request was made and the server responded with a
           * status code that falls out of the range of 2xx
           */
          const notifyErrors = Array.isArray(error.response.data.errors)
            ? JSON.stringify(error.response.data.errors)
            : error.response.data.errors;
          errorMessage = `GC Notify errored with status code ${error.response.status} and returned the following detailed errors ${notifyErrors}.`;
        } else if (error.request) {
          /*
           * The request was made but no response was received, `error.request`
           * is an instance of XMLHttpRequest in the browser and an instance
           * of http.ClientRequest in Node.js
           */
          errorMessage = `Error sending to Notify with request :${error.request}.`;
        }
      } else if (error instanceof Error) {
        errorMessage = `${(error as Error).message}.`;
      }

      throw new Error(
        `Failed to send submission through GC Notify to ${emailAddress}. Reason: ${errorMessage}.`
      );
    }
  }
}
