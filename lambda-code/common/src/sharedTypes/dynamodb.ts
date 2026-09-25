export type DynamoDbProcessableSubmission = {
  SubmissionID: string;
  FormID: string;
  CreatedAt: number;
  FormSubmissionLanguage: string;
  FormData: string;
  FormSubmissionHash: string;
  SecurityAttribute: string;
  Version: number;
  HasFileKeys: number;
  FileKeys?: string;
  NotificationID?: string;
  SendReceipt: string;
  NotifyProcessed?: boolean;
};

export const DynamoDbProcessableSubmissionProjectionExpression =
  "SubmissionID,FormID,CreatedAt,FormSubmissionLanguage,FormData,FormSubmissionHash,SecurityAttribute,Version,HasFileKeys,FileKeys,NotificationID,SendReceipt,NotifyProcessed";
