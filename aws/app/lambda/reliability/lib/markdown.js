const json2md = require("json2md");
const { extractFormData } = require("dataLayer");

module.exports = (formResponse, submissionID, language, createdAt) => {

  const title = `${language === "fr" ? (formResponse.form.emailSubjectFr
      ? formResponse.form.emailSubjectFr
      : formResponse.form.titleFr): (formResponse.form.emailSubjectEn
      ? formResponse.form.emailSubjectEn
      : formResponse.form.titleEn)}`;

  const stringifiedData = extractFormData(formResponse, language);
  const mdBody = stringifiedData.map((item) => {
    return { p: item };
  });

  let emailMarkdown = json2md([{ h1: title }, mdBody]);
  const isoCreatedAtString = new Date(parseInt(createdAt)).toISOString();

  // Using language attribute tags https://notification.canada.ca/format
  // This is done so screen readers can read in the correct voice
  if (language === "fr"){
    emailMarkdown =
        `[[fr]]\n${emailMarkdown}\nDate de soumission: ${isoCreatedAtString}\nID: ${submissionID}\n[[/fr]]`;
  }else{
    emailMarkdown =
        `[[en]]\n${emailMarkdown}\nSubmission Date: ${isoCreatedAtString}\nID: ${submissionID}\n[[/en]]`;
  }

  return emailMarkdown
};
