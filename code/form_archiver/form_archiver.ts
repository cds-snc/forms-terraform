import { deleteFormTemplatesMarkedAsArchived } from "./lib/templates.js";
import { Handler } from "aws-lambda";

export const handler: Handler = async () => {
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
        error: (error as Error).message,
      })
    );

    return {
      statusCode: "ERROR",
      error: (error as Error).message,
    };
  }
};
