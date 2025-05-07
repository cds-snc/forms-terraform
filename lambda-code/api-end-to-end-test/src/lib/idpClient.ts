import { createPrivateKey } from "node:crypto";
import { SignJWT } from "jose";
import axios from "axios";

export class IdpClient {
  private identityProviderUrl: string;
  private projectIdentifier: string;
  private privateApiKey: PrivateApiKey;

  public constructor(
    identityProviderUrl: string,
    projectIdentifier: string,
    privateApiKey: PrivateApiKey
  ) {
    this.identityProviderUrl = identityProviderUrl;
    this.projectIdentifier = projectIdentifier;
    this.privateApiKey = privateApiKey;
  }

  public generateAccessToken(): Promise<string> {
    const privateKey = createPrivateKey({ key: this.privateApiKey.key });

    const jsonWebTokenSigner = new SignJWT()
      .setProtectedHeader({ alg: "RS256", kid: this.privateApiKey.keyId })
      .setIssuedAt()
      .setIssuer(this.privateApiKey.userId)
      .setSubject(this.privateApiKey.userId)
      .setAudience(this.identityProviderUrl)
      .setExpirationTime("1 minute");

    return jsonWebTokenSigner
      .sign(privateKey)
      .then((signedJsonWebToken) =>
        axios.post(
          `${this.identityProviderUrl}/oauth/v2/token`,
          {
            grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
            assertion: signedJsonWebToken,
            scope: `openid profile urn:zitadel:iam:org:project:id:${this.projectIdentifier}:aud`,
          },
          {
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
            },
          }
        )
      )
      .then((response) => response.data.access_token as string)
      .catch((error) => {
        throw new Error("Failed to generate access token", { cause: error });
      });
  }
}
