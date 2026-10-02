export type DynamoDbProcessableSubmission = {
  SubmissionID: string;
  FormID: string;
  SendReceipt: string;
  CreatedAt: number;
  FormSubmissionLanguage: string;
  FormData: string;
  FormSubmissionHash: string;
  SecurityAttribute: string;
  Version: number;
  HasFileKeys: number;
  FileKeys?: string;
  NotificationID?: string;
};

export const DynamoDbProcessableSubmissionProjectionExpression =
  "SubmissionID,FormID,SendReceipt,FormData,FormSubmissionLanguage,CreatedAt,SecurityAttribute,Version,NotifyProcessed,FileKeys,NotificationID";
