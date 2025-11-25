import { ALLOWED_FILE_TYPES as GCFormsFileAttachmentAllowedTypes } from "@gcforms/core";
import { filetypeinfo } from "magic-bytes.js";
import path from "node:path";

// The magic-bytes package we use recommend providing the first 100 bytes of a file to detect most types listed in https://en.wikipedia.org/wiki/List_of_file_signatures
export function isFileValid(
  filePath: string,
  fileContentFirst100bytes: Uint8Array<ArrayBufferLike>
): boolean {
  try {
    // using slice to remove "." from extension
    const fileExtension = path.extname(filePath).slice(1);

    // path.extname returns an empty string is no extension was found
    if (fileExtension === "") {
      throw new Error(`File validation could not find any file extension in "${filePath}"`);
    }

    // making sure all strings are in lower case before comparing them
    const supportedMimeType = GCFormsFileAttachmentAllowedTypes.find((type) =>
      type.extensions.map((ext) => ext.toLowerCase()).includes(fileExtension.toLowerCase())
    )?.mime;

    if (supportedMimeType === undefined) {
      throw new Error(`File validation does not support extension "${fileExtension}"`);
    }

    const detectedFileTypeInfo = filetypeinfo(fileContentFirst100bytes);

    if (detectedFileTypeInfo.length === 0) {
      console.info(
        JSON.stringify({
          level: "info",
          msg: `File validation could not find any file type information in content but GC Forms supports file with extension "${fileExtension}" (MIME type: "${supportedMimeType}")`,
        })
      );

      return true;
    }

    /**
     * When magic-bytes.js detects a defined charset in a text based files it returns the information that the file is probably a TXT.
     * Any text based files like CSV could have such encoding, and thus should be accepted in this situation.
     */
    if (
      supportedMimeType.includes("text/") &&
      detectedFileTypeInfo.find((info) => info.mime?.includes("text/") !== undefined)
    ) {
      return true;
    }

    // magic-bytes.js sometimes does not return a MIME type but just a type name which almost always matches the extension name so we can use it to detect even more type mismatch occurrences
    const isDetectedFileTypeOrExtensionSupported =
      detectedFileTypeInfo.find(
        (info) => info.typename === fileExtension || info.extension === fileExtension
      ) !== undefined;

    const isDetectedMimeTypeSupported =
      detectedFileTypeInfo.find((info) => info.mime === supportedMimeType) !== undefined;

    if (isDetectedFileTypeOrExtensionSupported === false && isDetectedMimeTypeSupported === false) {
      console.warn(
        JSON.stringify({
          level: "warn",
          msg: `File validation detected type mismatch for file "${filePath}". Detected ${JSON.stringify(
            detectedFileTypeInfo
          )} but expected file with type name / extension "${fileExtension}" and MIME type "${supportedMimeType}".`,
        })
      );

      return false;
    }

    return true;
  } catch (error) {
    throw new Error(`Failed to check if file is valid. Reason: ${(error as Error).message}`);
  }
}
