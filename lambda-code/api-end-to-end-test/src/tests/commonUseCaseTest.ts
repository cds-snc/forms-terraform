import { ApiClient } from "@lib/apiClient.js";
import { SubmissionGenerator } from "@lib/submissionGenerator.js";
import { generateRandomString, pause } from "@lib/utils.js";

export class CommonUseCaseTest implements ApiTest {
  public name = "CommonUseCaseTest";

  private submissionGenerator: SubmissionGenerator;
  private apiClient: ApiClient;
  private privateApiKey: PrivateApiKey;

  public constructor(
    submissionGenerator: SubmissionGenerator,
    apiClient: ApiClient,
    privateApiKey: PrivateApiKey
  ) {
    this.submissionGenerator = submissionGenerator;
    this.apiClient = apiClient;
    this.privateApiKey = privateApiKey;
  }

  public async run(): Promise<void> {
    console.info("Creating submission...");

    const randomSubmissionAnswers: Record<string, string> = {
      1: generateRandomString(10),
    };

    const submissionName = await this.submissionGenerator.generateSubmission(
      randomSubmissionAnswers
    );

    console.info("Retrieving form template...");

    await this.apiClient.getFormTemplate();

    console.info("Looking for new submission...");

    const newSubmissionFound = await this.findNewSubmission(submissionName);

    if (newSubmissionFound === false) {
      throw new Error(`Failed to find new submission. Submission name: ${submissionName}`);
    }

    console.info("Retrieving encrypted submission...");

    const encryptedSubmission = (await this.apiClient.getFormSubmission(submissionName)).payload;

    console.info("Decrypting submission...");

    const decryptedSubmission = ApiClient.decryptFormSubmission(
      encryptedSubmission,
      this.privateApiKey
    );

    const formSubmission = JSON.parse(decryptedSubmission) as FormSubmission;

    console.info("Validating submission integrity...");

    const integrityCheckResult = ApiClient.verifyFormSubmissionIntegrity(
      formSubmission.answers,
      formSubmission.checksum
    );

    if (integrityCheckResult === false) {
      throw new Error(
        `Failed to validate submission integrity. Submission answers: ${formSubmission.answers} / Submission checksum: ${formSubmission.checksum}`
      );
    }

    console.info("Validating submission answers...");

    if (formSubmission.answers !== JSON.stringify(randomSubmissionAnswers)) {
      throw new Error(
        `Failed to validate submission answers. Actual answers: ${
          formSubmission.answers
        } / Expected: ${JSON.stringify(randomSubmissionAnswers)}`
      );
    }

    console.info("Confirming submission...");

    await this.apiClient.confirmFormSubmission(submissionName, formSubmission.confirmationCode);
  }

  private async findNewSubmission(submissionName: string): Promise<boolean> {
    for (let i = 0; i < 3; i++) {
      const newSubmissions = (await this.apiClient.getNewFormSubmissions()).payload;

      if (newSubmissions.map((s) => s.name).includes(submissionName)) {
        return true;
      }

      await pause(5);
    }

    return false;
  }
}
