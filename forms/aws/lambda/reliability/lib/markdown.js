const json2md = require("json2md");
const { extractFormData } = require("dataLayer");

module.exports = (formResponse) => {
  const subjectEn = formResponse.form.emailSubjectEn
    ? formResponse.form.emailSubjectEn
    : formResponse.form.titleEn;
  const subjectFr = formResponse.form.emailSubjectFr
    ? formResponse.form.emailSubjectFr
    : formResponse.form.titleFr;

  const title = `${subjectEn} / ${subjectFr}`;

  const stringifiedData = extractFormData(formResponse);
  const mdBody = stringifiedData.map((item) => {
    return { p: item };
  });
  const emailBody = json2md([{ h1: title }, mdBody]);

  return emailBody;
};
