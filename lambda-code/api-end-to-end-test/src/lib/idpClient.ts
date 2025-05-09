import { createPrivateKey } from "node:crypto";
import { SignJWT } from "jose";
import axios from "axios";
import https from "https";

const noSslHttpsAgent = new https.Agent({
  rejectUnauthorized: false,
});

export class IdpClient {
  private identityProviderTrustedDomain: string;
  private identityProviderUrl: string;
  private projectIdentifier: string;
  private privateApiKey: PrivateApiKey;

  public constructor(
    identityProviderTrustedDomain: string,
    identityProviderUrl: string,
    projectIdentifier: string,
    privateApiKey: PrivateApiKey
  ) {
    this.identityProviderTrustedDomain = identityProviderTrustedDomain;
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
      .setAudience(`https://${this.identityProviderTrustedDomain}`) // To bypass JWT Audience check from IdP
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
            httpsAgent: noSslHttpsAgent, // To bypass self signed SSL certificate barrier
            headers: {
              Host: this.identityProviderTrustedDomain, // To bypass HTTP Host check from IdP
              "Content-Type": "application/x-www-form-urlencoded",
            },
          }
        )
      )
      .then((response) => response.data.access_token as string)
      .catch((error) => {
        throw new Error(`Failed to generate access token. Reason: ${(error as Error).message}`);
      });
  }
}
