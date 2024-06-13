import { deleteFormTemplatesMarkedAsArchived } from "./lib/templates.js";
import { Handler } from "aws-lambda";

export const handler: Handler = async () => {
  try {
    await deleteFormTemplatesMarkedAsArchived();

    console.log(
      JSON.stringify({
        level: "info",
        status: "success",
        msg: "Form Archiver ran successfully.",
      })
    );

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    // Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        status: "failed",
        msg: "Failed to run Form Templates Archiver.",
        error: (error as Error).message,
      })
    );

    return {
      statusCode: "ERROR",
      error: (error as Error).message,
    };
  }
};
