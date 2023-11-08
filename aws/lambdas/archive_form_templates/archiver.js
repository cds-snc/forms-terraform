const { deleteFormTemplatesMarkedAsArchived } = require("templates");

exports.handler = async (event) => {
  try {
    await deleteFormTemplatesMarkedAsArchived();

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    // Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run Form Templates Archiver.",
        error: error.message,
      })
    );

    return {
      statusCode: "ERROR",
      error: error.message,
    };
  }
};