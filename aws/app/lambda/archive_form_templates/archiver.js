const { deleteFormTemplatesMarkedAsArchived } = require("templates");

exports.handler = async (event) => {
  try {
    await deleteFormTemplatesMarkedAsArchived();
    return { status: true };
  } catch (error) {
    throw new Error(`Could not delete archived templates because ${error.message}`);
  }
};