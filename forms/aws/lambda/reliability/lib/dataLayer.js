// Email submission data manipulation

module.exports = function extractFormData(submission) {
  const formResponses = submission.responses;
  const formOrigin = submission.form;
  const dataCollector = [];
  formOrigin.layout.map((qID) => {
    const question = formOrigin.elements.find((element) => element.id === qID);
    if (question) {
      handleType(question, formResponses[question.id], dataCollector);
    } else {
      console.error(`Failed component ID look up ${qID} on form ID ${formOrigin.id}`);
    }
  });
  return dataCollector;
};

function handleType(question, response, collector) {
  // Add i18n here later on?
  // Do we detect lang submission or output with mixed lang?
  const qTitle = question.properties.titleEn;
  switch (question.type) {
    case "textField":
    case "textArea":
    case "dropdown":
    case "radio":
      handleTextResponse(qTitle, response, collector);
      break;

    case "checkbox":
      handleArrayResponse(qTitle, response, collector);
      break;
    case "dynamicRow":
      handleDynamicForm(qTitle, response, question.properties.subElements, collector);
      break;
    case "fileInput":
      break;
  }
}

function handleDynamicForm(title, response, question, collector) {
  const responseCollector = response.map((row, rIndex) => {
    const rowCollector = [];
    question.map((qItem, qIndex) => {
      // Add i18n here eventually?
      const qTitle = qItem.properties.titleEn;
      switch (qItem.type) {
        case "textField":
        case "textArea":
        case "dropdown":
        case "radio":
          handleTextResponse(qTitle, row[qIndex], rowCollector);
          break;

        case "checkbox":
          handleArrayResponse(qTitle, row[qIndex], rowCollector);
          break;
      }
    });
    rowCollector.unshift(`Item ${rIndex + 1}`);
    return rowCollector.join(String.fromCharCode(13));
  });
  responseCollector.unshift(title);
  collector.push(responseCollector.join(String.fromCharCode(13)));
}

function handleArrayResponse(title, response, collector) {
  if (response.length) {
    if (Array.isArray(response)) {
      const responses = response
        .map((item) => {
          return `- ${item}`;
        })
        .join(String.fromCharCode(13));
      collector.push(`${title}${String.fromCharCode(13)}${responses}`);
      return;
    } else {
      handleTextResponse(title, response, collector);
      return;
    }
  }
  collector.push(`${title}${String.fromCharCode(13)}- No response`);
}

function handleTextResponse(title, response, collector) {
  if (response !== undefined && response !== null) {
    collector.push(`${title}${String.fromCharCode(13)}-${response}`);
    return;
  }

  collector.push(`${title}${String.fromCharCode(13)}- No Response`);
}
