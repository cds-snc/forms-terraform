export interface FileAttachement {
  name: string;
  path: string;
}

/**
 * Given a form submission JSON string, returns an array of file attachments objects that
 * includes the file name, S3 object URL.
 */
export function getFileAttachments(formSubmission: string): FileAttachement[] {
  const attachmentPrefix = "form_attachments/";
  const attachmentRegex =
    /^form_attachments\/\d{4}-\d{2}-\d{2}\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/.+$/;

  // Check file attachments exist by checking the form submission for the
  // file attachment prefix that's part of the uploaded file's S3 object key
  if (formSubmission.indexOf(attachmentPrefix) > -1) {
    // Be more explicit in the attachment check to avoid false positives
    const jsonObj = JSON.parse(formSubmission);
    return Object.values<string>(jsonObj)
      .filter((value) => attachmentRegex.test(value))
      .map((value) => ({ name: getFileNameFromPath(value), path: value }));
  }

  return [];
}

function getFileNameFromPath(filePath: string): string {
  return filePath.substring(filePath.lastIndexOf("/") + 1);
}