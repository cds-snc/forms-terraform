import axios, { AxiosResponseHeaders, RawAxiosResponseHeaders, type AxiosInstance } from "axios";
import { privateDecrypt, createDecipheriv, createHash } from "node:crypto";

export class ApiClient {
  private formId: string;
  private httpClient: AxiosInstance;

  public constructor(formId: string, apiUrl: string, accessToken: string) {
    this.formId = formId;

    this.httpClient = axios.create({
      baseURL: apiUrl,
      timeout: 3000,
      headers: { Authorization: `Bearer ${accessToken}` },
    });
  }

  public getFormTemplate(): Promise<ApiResponse<Record<string, unknown>>> {
    return this.httpClient
      .get<Record<string, unknown>>(`/v1/forms/${this.formId}/template`)
      .then((response) => {
        return {
          status: response.status,
          rateLimitStatus: ApiClient.rateLimitStatusFromResponseHeaders(response.headers),
          payload: response.data,
        } as ApiResponse<Record<string, unknown>>;
      })
      .catch((error) => {
        if (error.response) {
          return {
            status: error.response.status,
            rateLimitStatus: ApiClient.rateLimitStatusFromResponseHeaders(error.response.headers),
          } as ApiResponse<Record<string, unknown>>;
        } else {
          throw new Error("Failed to retrieve form template", { cause: error });
        }
      });
  }

  public getNewFormSubmissions(): Promise<ApiResponse<NewFormSubmission[]>> {
    return this.httpClient
      .get<NewFormSubmission[]>(`/v1/forms/${this.formId}/submission/new`)
      .then((response) => {
        return {
          status: response.status,
          rateLimitStatus: ApiClient.rateLimitStatusFromResponseHeaders(response.headers),
          payload: response.data,
        } as ApiResponse<NewFormSubmission[]>;
      })
      .catch((error) => {
        if (error.response) {
          return {
            status: error.response.status,
            rateLimitStatus: ApiClient.rateLimitStatusFromResponseHeaders(error.response.headers),
          } as ApiResponse<NewFormSubmission[]>;
        } else {
          throw new Error("Failed to retrieve new form submissions", {
            cause: error,
          });
        }
      });
  }

  public getFormSubmission(submissionName: string): Promise<ApiResponse<EncryptedFormSubmission>> {
    return this.httpClient
      .get<EncryptedFormSubmission>(`/v1/forms/${this.formId}/submission/${submissionName}`)
      .then((response) => {
        return {
          status: response.status,
          rateLimitStatus: ApiClient.rateLimitStatusFromResponseHeaders(response.headers),
          payload: response.data,
        } as ApiResponse<EncryptedFormSubmission>;
      })
      .catch((error) => {
        if (error.response) {
          return {
            status: error.response.status,
            rateLimitStatus: ApiClient.rateLimitStatusFromResponseHeaders(error.response.headers),
          } as ApiResponse<EncryptedFormSubmission>;
        } else {
          throw new Error("Failed to retrieve form submission", { cause: error });
        }
      });
  }

  public confirmFormSubmission(
    submissionName: string,
    confirmationCode: string
  ): Promise<ApiResponse<void>> {
    return this.httpClient
      .put<void>(
        `/v1/forms/${this.formId}/submission/${submissionName}/confirm/${confirmationCode}`
      )
      .then((response) => {
        return {
          status: response.status,
          rateLimitStatus: ApiClient.rateLimitStatusFromResponseHeaders(response.headers),
          payload: response.data,
        } as ApiResponse<void>;
      })
      .catch((error) => {
        if (error.response) {
          return {
            status: error.response.status,
            rateLimitStatus: ApiClient.rateLimitStatusFromResponseHeaders(error.response.headers),
          } as ApiResponse<void>;
        } else {
          throw new Error("Failed to confirm form submission", { cause: error });
        }
      });
  }

  public static decryptFormSubmission(
    encryptedSubmission: EncryptedFormSubmission,
    privateApiKey: PrivateApiKey
  ): string {
    const privateKey = {
      key: privateApiKey.key,
      oaepHash: "sha256",
    };

    const decryptedKey = privateDecrypt(
      privateKey,
      Buffer.from(encryptedSubmission.encryptedKey, "base64")
    );

    const decryptedNonce = privateDecrypt(
      privateKey,
      Buffer.from(encryptedSubmission.encryptedNonce, "base64")
    );

    const decryptedAuthTag = privateDecrypt(
      privateKey,
      Buffer.from(encryptedSubmission.encryptedAuthTag, "base64")
    );

    const gcmDecipher = createDecipheriv("aes-256-gcm", decryptedKey, decryptedNonce);

    gcmDecipher.setAuthTag(decryptedAuthTag);

    const encryptedData = Buffer.from(encryptedSubmission.encryptedResponses, "base64");

    const decryptedData = Buffer.concat([gcmDecipher.update(encryptedData), gcmDecipher.final()]);

    return decryptedData.toString("utf8");
  }

  public static verifyFormSubmissionIntegrity(answers: string, checksum: string): boolean {
    const generatedChecksumFromReceivedData = createHash("md5").update(answers).digest("hex");
    return generatedChecksumFromReceivedData.toString() === checksum;
  }

  private static rateLimitStatusFromResponseHeaders(
    headers: RawAxiosResponseHeaders | AxiosResponseHeaders
  ): RateLimitStatus {
    return {
      limit: Number(headers["x-ratelimit-limit"]),
      remanining: Number(headers["x-ratelimit-remaining"]),
      reset: new Date(headers["x-ratelimit-reset"]),
      retryAfter: headers["retry-after"] ? Number(headers["retry-after"]) : undefined,
    };
  }
}
