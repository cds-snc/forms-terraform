import { Handler } from "aws-lambda";
import { prisma } from "@gcforms/database";

export const handler: Handler = async () => {
  try {
    await prisma.template.deleteMany({
      where: {
        ttl: {
          not: null,
          lt: new Date(),
        },
      },
    });

    console.log(
      JSON.stringify({
        level: "info",
        status: "success",
        msg: "Form Archiver ran successfully.",
      })
    );
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

    throw error;
  }
};
