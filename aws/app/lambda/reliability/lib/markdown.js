const json2md = require("json2md");
const { extractFormData } = require("dataLayer");

module.exports = (formResponse, language, submissionDateTime) => {
  const title = `${language === "fr" ? (formResponse.form.emailSubjectFr
      ? formResponse.form.emailSubjectFr
      : formResponse.form.titleFr): (formResponse.form.emailSubjectEn
      ? formResponse.form.emailSubjectEn
      : formResponse.form.titleEn)}`;

  const stringifiedData = extractFormData(formResponse, language);
  const mdBody = stringifiedData.map((item) => {
    return { p: item };
  });
 
  let formatedDate;  
  try {
      formatedDate = submissionDateTime ? new Date(submissionDateTime * 1000).toISOString() : "";
   }catch(error){
      console.log(error);
  }  
  // use Notify lang attribute to denote the language https://notification.canada.ca/format
  const emailBody = language === "fr" ?
      "[[fr]]\n" + json2md([{ h1: title }, { h5: "Date" }, { p: formatedDate }, mdBody])+ "\n[[/fr]]":
      "[[en]]\n" + json2md([{ h1: title }, { h5: "Date" }, { p: formatedDate }, mdBody])+ "\n[[/en]]";

  return emailBody;
};
