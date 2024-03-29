import { createHash, randomUUID } from "crypto";
import { Handler, DynamoDBStreamEvent, StreamRecord } from "aws-lambda";

export const handler: Handler = async (event: DynamoDBStreamEvent) => {
  try {
    event.Records.filter((r) => {
      if (r.eventName === "INSERT")
        return r.dynamodb?.NewImage?.NAME_OR_CONF?.S?.startsWith("NAME#");
      else return r.dynamodb?.OldImage?.NAME_OR_CONF?.S?.startsWith("NAME#"); // Someone could have changed the value during the update so we need to filter on the previous one.
    }).forEach((r) => {
      if (r.eventName === "INSERT") checkInsertEvent(r.dynamodb?.NewImage);
      else checkModifyEvent(r.dynamodb?.OldImage, r.dynamodb?.NewImage);
    });

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    // Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        severity: 1,
        msg: "Failed to run Vault data integrity check.",
        error: (error as Error).message,
      })
    );

    return {
      statusCode: "ERROR",
      error: (error as Error).message,
    };
  }
};

function checkInsertEvent(data: StreamRecord["NewImage"]) {
  let formSubmissionId: string | null = null;

  try {
    formSubmissionId = data?.SubmissionID?.S ?? null;
    const formSubmissionData = data?.FormSubmission?.S ?? null;
    const formSubmissionValidHash = data?.FormSubmissionHash?.S ?? null;

    if (!formSubmissionId || !formSubmissionData) {
      throw new Error("Missing data in record.");
    }

    if (!formSubmissionValidHash) {
      console.log(
        JSON.stringify({
          level: "info",
          msg: `Could not check data integrity for inserted submission (submissionId: ${formSubmissionId}). No valid hash was found in the record. This can happen if the submission was created prior to the introduction of Vault data integrity checks.`,
        })
      );
      return;
    }

    const formSubmissionHashToValidate = createHash("md5").update(formSubmissionData).digest("hex");

    if (formSubmissionHashToValidate !== formSubmissionValidHash) {
      throw new Error(
        `Hash mismatch detected. Expected ${formSubmissionValidHash}, got ${formSubmissionHashToValidate}.`
      );
    }
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        severity: 1,
        msg: `Integrity check failure on inserted submission (submissionId: ${formSubmissionId}).`,
        error: (error as Error).message,
      })
    );
  }
}

function checkModifyEvent(oldData: StreamRecord["OldImage"], newData: StreamRecord["NewImage"]) {
  let oldSubmissionID: string | null = null;
  let newSubmissionID: string | null = null;

  try {
    const oldFormId = oldData?.FormID?.S ?? null;
    const oldNameOfConf = oldData?.NAME_OR_CONF?.S ?? null;
    const oldConfirmationCode = oldData?.ConfirmationCode?.S ?? null;
    const oldCreatedAt = oldData?.CreatedAt?.N ?? null;
    const oldFormSubmission = oldData?.FormSubmission?.S ?? null;
    const oldName = oldData?.Name?.S ?? null;
    oldSubmissionID = oldData?.SubmissionID?.S ?? null;
    const oldFormSubmissionHash = oldData?.FormSubmissionHash?.S ?? null;

    const newFormId = newData?.FormID?.S ?? null;
    const newNameOfConf = newData?.NAME_OR_CONF?.S ?? null;
    const newConfirmationCode = newData?.ConfirmationCode?.S ?? null;
    const newCreatedAt = newData?.CreatedAt?.N ?? null;
    const newFormSubmission = newData?.FormSubmission?.S ?? null;
    const newName = newData?.Name?.S ?? null;
    newSubmissionID = newData?.SubmissionID?.S ?? null;
    const newFormSubmissionHash = newData?.FormSubmissionHash?.S ?? null;

    if (!oldFormSubmissionHash && !newFormSubmissionHash) {
      console.log(
        JSON.stringify({
          level: "info",
          msg: `Could not check data integrity for modified submission (oldSubmissionID: ${oldSubmissionID}, newSubmissionID: ${newSubmissionID}). No valid hash was found in the record. This can happen if the submission was created prior to the introduction of Vault data integrity checks.`,
        })
      );
      return;
    }

    if (
      !oldFormId ||
      !oldNameOfConf ||
      !oldConfirmationCode ||
      !oldCreatedAt ||
      !oldFormSubmission ||
      !oldName ||
      !oldSubmissionID ||
      !oldFormSubmissionHash
    ) {
      throw new Error("Missing data in record old image.");
    }

    if (
      !newFormId ||
      !newNameOfConf ||
      !newConfirmationCode ||
      !newCreatedAt ||
      !newFormSubmission ||
      !newName ||
      !newSubmissionID ||
      !newFormSubmissionHash
    ) {
      throw new Error("Missing data in record new image.");
    }

    const oldDataAsString = `${oldFormId}${oldNameOfConf}${oldConfirmationCode}${String(
      oldCreatedAt
    )}${oldFormSubmission}${oldName}${oldSubmissionID}${oldFormSubmissionHash}`;
    const newDataAsString = `${newFormId}${newNameOfConf}${newConfirmationCode}${String(
      newCreatedAt
    )}${newFormSubmission}${newName}${newSubmissionID}${newFormSubmissionHash}`;

    if (oldDataAsString !== newDataAsString) {
      const investigationId = randomUUID();

      console.log(
        JSON.stringify({
          level: "info",
          investigationId,
          oldImage: oldData,
          newImage: newData,
          msg: "Logging old and new images for investigation.",
        })
      );

      throw new Error(
        `Data mismatch detected. Both old and new images have been dumped in the logs for investigation (investigationId: ${investigationId}).`
      );
    }
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        severity: 1,
        msg: `Integrity check failure on modified submission (oldSubmissionID: ${oldSubmissionID} , newSubmissionID: ${newSubmissionID}).`,
        error: (error as Error).message,
      })
    );
  }
}
