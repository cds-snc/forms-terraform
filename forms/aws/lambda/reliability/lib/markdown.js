const json2md = require("json2md");
const extractFormData = require("dataLayer");

module.exports = (formResponse) => {
  const title = `${formResponse.form.titleEn} / ${formResponse.form.titleFr}`;
  const stringifiedData = extractFormData(formResponse);
  const mdBody = stringifiedData.map((item) => {
    return { p: item };
  });
  const emailBody = json2md([{ h1: title }, mdBody]);

  return emailBody;
};

// test change
