type PrivateApiKey = {
  keyId: string;
  key: string;
  userId: string;
  formId: string;
};

type NewFormSubmission = {
  name: string;
  createdAt: number;
};

type EncryptedFormSubmission = {
  encryptedResponses: string;
  encryptedKey: string;
  encryptedNonce: string;
  encryptedAuthTag: string;
};

type FormSubmission = {
  confirmationCode: string;
  answers: string;
  checksum: string;
};

type RateLimitStatus = {
  limit: number;
  remanining: number;
  reset: Date;
  retryAfter?: number;
};

type ApiResponse<T> = {
  status: number;
  rateLimitStatus: RateLimitStatus;
  payload: T;
};
