import path from "node:path";
import { ALLOWED_FILE_TYPES as GcFormsFileAttachmentAllowedTypes } from "@gcforms/core";
import { filetypeinfo } from "magic-bytes.js";
import { Either } from "purify-ts";

// The magic-bytes package we use recommend providing the first 100 bytes of a file to detect most types listed in https://en.wikipedia.org/wiki/List_of_file_signatures
export function isFileValid(filePath: string, fileFirst100Bytes: Uint8Array<ArrayBufferLike>): Either<Error, boolean> {
  return Either.encase(() => {
    const { name: fileName, ext: fileExtensionDotIncluded } = path.parse(filePath);

    // Either file name or extension is missing so we flag it as malicious
    if (fileName === "" || fileExtensionDotIncluded === "") {
      return false;
    }

    const fileExtension = fileExtensionDotIncluded.slice(1);

    // Making sure all strings are in lower case before comparing them
    const supportedMimeType = GcFormsFileAttachmentAllowedTypes.find((type) => type.extensions.map((ext) => ext.toLowerCase()).includes(fileExtension.toLowerCase()))?.mime;

    if (supportedMimeType === undefined) {
      throw new Error(`Unsupported extension "${fileExtension}"`);
    }

    const detectedFileTypeInfo = filetypeinfo(fileFirst100Bytes);

    if (detectedFileTypeInfo.length === 0) {
      console.info(
        JSON.stringify({
          level: "info",
          msg: `File validation could not find any file type information in content but GC Forms supports file with extension "${fileExtension}" (MIME type: "${supportedMimeType}")`,
        }),
      );

      return true; // Could not find any file type information in content but we still support provided file extension
    }

    /**
     * When magic-bytes.js detects a defined charset in a text based files it returns the information that the file is probably a TXT.
     * Any text based files like CSV could have such encoding, and thus should be accepted in this situation.
     */
    if (supportedMimeType.includes("text/") && detectedFileTypeInfo.find((info) => info.mime?.includes("text/") !== undefined)) {
      return true;
    }

    // magic-bytes.js sometimes does not return a MIME type but just a type name which almost always matches the extension name so we can use it to detect even more type mismatch occurrences
    const isDetectedFileTypeOrExtensionSupported = detectedFileTypeInfo.find((info) => info.typename === fileExtension || info.extension === fileExtension) !== undefined;

    const isDetectedMimeTypeSupported = detectedFileTypeInfo.find((info) => info.mime === supportedMimeType) !== undefined;

    if (isDetectedFileTypeOrExtensionSupported === false && isDetectedMimeTypeSupported === false) {
      return false; // File type mismatch detected
    }

    return true;
  }).mapLeft((error) => new Error("Failed to validate file", { cause: error }));
}
