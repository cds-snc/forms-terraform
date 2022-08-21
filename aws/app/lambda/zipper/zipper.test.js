"use strict";

const axios = require("axios");
const { mockClient } = require("aws-sdk-client-mock");
const { S3Client, PutObjectTaggingCommand } = require("@aws-sdk/client-s3");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { STSClient, AssumeRoleCommand } = require("@aws-sdk/client-sts");

const mockS3Client = mockClient(S3Client);
const mockSecretManagerClient = mockClient(SecretsManagerClient);
const mockSTSClient = mockClient(STSClient);
mockSecretManagerClient.on(GetSecretValueCommand).resolves({
  SecretString: "someSuperSecretValue",
});

const { handler, helpers } = require("./app.js");
const {
  getEventAttribute,
  getRecordEventSource,
  getRoleCredentials,
  getS3ObjectFromRecord,
  getS3Client,
  initConfig,
  isS3Folder,
  parseS3Url,
  startS3ObjectScan,
  tagS3Object,
} = helpers;

jest.mock("axios");

const TEST_TIME = new Date(1978, 3, 30).getTime();
beforeAll(() => {
  jest.useFakeTimers().setSystemTime(TEST_TIME);
});

beforeEach(() => {
  jest.resetAllMocks();
  mockS3Client.reset();
  mockSecretManagerClient.reset();
  mockSTSClient.reset();
});

describe("handler", () => {
  test("records success", async () => {
    const event = {
      AccountId: "123456789012",
      RequestId: "1234asdf",
      Records: [
        {
          eventSource: "aws:s3",
          s3: {
            bucket: { name: "foo" },
            object: { key: "bar" },
          },
        },
        {
          eventSource: "aws:s3",
          s3: {
            bucket: { name: "smaug" },
            object: { key: "gold/" },
          },
        },
        {
          EventSource: "aws:sns",
          Sns: {
            MessageAttributes: {
              "request-id": { Value: "zxcv9584" },
              "av-filepath": { Value: "s3://bam/baz" },
              "av-status": { Value: "SPIFY" },
              "av-checksum": { Value: "42" },
              "aws-account": { Value: "123456789012" },
            },
          },
        },
        {
          eventSource: "custom:rescan",
          s3ObjectUrl: "s3://boom/bing",
        },
        {
          EventSource: "aws:sns",
          Sns: {
            MessageAttributes: {
              "request-id": { Value: "poiu0987" },
              "av-filepath": { Value: "s3://frodo/bagginsssis" },
              "av-status": { Value: "error" },
              "av-checksum": { Value: "None" },
              "aws-account": { Value: "210987654321" },
            },
          },
        },
      ],
    };
    const expectedResponse = {
      status: 200,
      body: "Event records processesed: 5, Errors: 0",
    };

    axios.post.mockResolvedValue({ status: 200 });
    mockS3Client.on(PutObjectTaggingCommand).resolves({ VersionId: "yeet" });
    mockSTSClient.on(AssumeRoleCommand).resolves({ Credentials: {} });

    const response = await handler(event, {});
    expect(response).toEqual(expectedResponse);
    expect(mockS3Client).toHaveReceivedNthCommandWith(1, PutObjectTaggingCommand, {
      Bucket: "foo",
      Key: "bar",
      Tagging: {
        TagSet: [
          { Key: "av-scanner", Value: "clamav" },
          { Key: "av-status", Value: "in_progress" },
          { Key: "av-timestamp", Value: TEST_TIME },
          { Key: "request-id", Value: "1234asdf" },
        ],
      },
    });
    expect(mockS3Client).toHaveReceivedNthCommandWith(2, PutObjectTaggingCommand, {
      Bucket: "bam",
      Key: "baz",
      Tagging: {
        TagSet: [
          { Key: "av-scanner", Value: "clamav" },
          { Key: "av-status", Value: "SPIFY" },
          { Key: "av-timestamp", Value: TEST_TIME },
          { Key: "av-checksum", Value: "42" },
          { Key: "request-id", Value: "zxcv9584" },
        ],
      },
    });
    expect(mockS3Client).toHaveReceivedNthCommandWith(3, PutObjectTaggingCommand, {
      Bucket: "boom",
      Key: "bing",
      Tagging: {
        TagSet: [
          { Key: "av-scanner", Value: "clamav" },
          { Key: "av-status", Value: "in_progress" },
          { Key: "av-timestamp", Value: TEST_TIME },
          { Key: "request-id", Value: "zxcv9584" },
        ],
      },
    });
    expect(mockS3Client).toHaveReceivedNthCommandWith(4, PutObjectTaggingCommand, {
      Bucket: "frodo",
      Key: "bagginsssis",
      Tagging: {
        TagSet: [
          { Key: "av-scanner", Value: "clamav" },
          { Key: "av-status", Value: "error" },
          { Key: "av-timestamp", Value: TEST_TIME },
          { Key: "request-id", Value: "poiu0987" },
        ],
      },
    });
    expect(mockSTSClient).toHaveReceivedNthCommandWith(1, AssumeRoleCommand, {
      RoleArn: "arn:aws:iam::123456789012:role/ScanFilesGetObjects",
      RoleSessionName: "s3-scan-object",
    });
    expect(mockSTSClient).toHaveReceivedNthCommandWith(2, AssumeRoleCommand, {
      RoleArn: "arn:aws:iam::210987654321:role/ScanFilesGetObjects",
      RoleSessionName: "s3-scan-object",
    });
  });

  test("records failed, failed to start", async () => {
    const event = {
      AccountId: "123456789012",
      RequestId: "qwer7890",
      Records: [
        {
          eventSource: "aws:s3",
          s3: {
            bucket: { name: "foo" },
            object: { key: "bar" },
          },
        },
      ],
    };
    const expectedResponse = {
      status: 422,
      body: "Event records processesed: 1, Errors: 1",
    };

    axios.post.mockResolvedValue({ status: 500 });
    mockS3Client.on(PutObjectTaggingCommand).resolves({ VersionId: "yeet" });
    mockSTSClient.on(AssumeRoleCommand).resolves({ Credentials: {} });

    const response = await handler(event, {});
    expect(response).toEqual(expectedResponse);
    expect(mockS3Client).toHaveReceivedNthCommandWith(1, PutObjectTaggingCommand, {
      Bucket: "foo",
      Key: "bar",
      Tagging: {
        TagSet: [
          { Key: "av-scanner", Value: "clamav" },
          { Key: "av-status", Value: "failed_to_start" },
          { Key: "av-timestamp", Value: TEST_TIME },
          { Key: "request-id", Value: "qwer7890" },
        ],
      },
    });
    expect(mockSTSClient).toHaveReceivedNthCommandWith(1, AssumeRoleCommand, {
      RoleArn: "arn:aws:iam::123456789012:role/ScanFilesGetObjects",
      RoleSessionName: "s3-scan-object",
    });
  });

  test("records failed, undefined reponse", async () => {
    const event = {
      AccountId: "654321789012",
      RequestId: "zxcv5678",
      Records: [
        {
          eventSource: "aws:s3",
          s3: {
            bucket: { name: "foo" },
            object: { key: "bar" },
          },
        },
      ],
    };
    const expectedResponse = {
      status: 422,
      body: "Event records processesed: 1, Errors: 1",
    };

    axios.post.mockResolvedValue(undefined);
    mockS3Client.on(PutObjectTaggingCommand).resolves({ VersionId: "yeet" });
    mockSTSClient.on(AssumeRoleCommand).resolves({ Credentials: {} });

    const response = await handler(event, {});
    expect(response).toEqual(expectedResponse);
    expect(mockS3Client).toHaveReceivedNthCommandWith(1, PutObjectTaggingCommand, {
      Bucket: "foo",
      Key: "bar",
      Tagging: {
        TagSet: [
          { Key: "av-scanner", Value: "clamav" },
          { Key: "av-status", Value: "failed_to_start" },
          { Key: "av-timestamp", Value: TEST_TIME },
          { Key: "request-id", Value: "zxcv5678" },
        ],
      },
    });
    expect(mockSTSClient).toHaveReceivedNthCommandWith(1, AssumeRoleCommand, {
      RoleArn: "arn:aws:iam::654321789012:role/ScanFilesGetObjects",
      RoleSessionName: "s3-scan-object",
    });
  });

  test("records failed, invalid event source", async () => {
    const event = {
      Records: [
        {
          eventSource: "muffins",
        },
      ],
    };
    const expectedResponse = {
      status: 422,
      body: "Event records processesed: 1, Errors: 1",
    };

    axios.post.mockResolvedValue({ status: 200 });
    mockS3Client.on(PutObjectTaggingCommand).resolves({ VersionId: "yeet" });

    const response = await handler(event, {});
    expect(response).toEqual(expectedResponse);
  });
});

describe("getEventAttribute", () => {
  test("attribute exists", () => {
    const record = {
      Sns: {
        MessageAttributes: {
          "aws-account": { Value: "654321789012" },
          "request-id": { Value: "qwer7890" },
        },
      },
    };
    expect(getEventAttribute("aws:s3", { AccountId: "123456789012" }, null, { root: "AccountId" })).toBe(
      "123456789012"
    );
    expect(getEventAttribute("aws:sns", null, record, { sns: "aws-account" })).toBe("654321789012");
    expect(getEventAttribute("aws:sns", null, record, { sns: "request-id" })).toBe("qwer7890");
    expect(getEventAttribute("custom:rescan", { RequestId: "210987654321" }, null, { root: "RequestId" })).toBe(
      "210987654321"
    );
  });

  test("attribute does not exist", () => {
    const record = {
      Sns: {
        MessageAttributes: {},
      },
    };
    expect(getEventAttribute("foo", { AccountId: "123456789012" }, null, { root: "AccountId" })).toBe(null);
    expect(getEventAttribute("aws:s3", {}, null, { root: "AccountId" })).toBe(null);
    expect(getEventAttribute("aws:sns", {}, record, { sns: "aws-account" })).toBe(null);
    expect(getEventAttribute("custom:rescan", {}, null, { root: "FooBar" })).toBe(null);
  });
});

describe("getRecordEventSource", () => {
  test("valid event sources", () => {
    expect(getRecordEventSource({ eventSource: "aws:s3" })).toBe("aws:s3");
    expect(getRecordEventSource({ EventSource: "aws:sns" })).toBe("aws:sns");
    expect(getRecordEventSource({ EventSource: "custom:rescan" })).toBe("custom:rescan");
  });

  test("invalid event sources", () => {
    expect(getRecordEventSource({ eventSource: "aws:s3:ca-central-1" })).toBe(null);
    expect(getRecordEventSource({ EventSource: "aws:ec2" })).toBe(null);
    expect(getRecordEventSource({ eventSource: null })).toBe(null);
    expect(getRecordEventSource({ eventSource: undefined })).toBe(null);
    expect(getRecordEventSource({ eventSource: "pohtaytoes" })).toBe(null);
    expect(getRecordEventSource({})).toBe(null);
  });
});

describe("getRoleCredentials", () => {
  test("successfully assumes role", async () => {
    const response = {
      Credentials: {
        AccessKeyId: "why",
        SecretAccessKey: "aws",
        SessionToken: "whyyyyy",
      },
    };
    mockSTSClient.on(AssumeRoleCommand).resolves(response);
    const credentials = await getRoleCredentials(mockSTSClient, "foo");

    expect(credentials).toEqual({
      accessKeyId: "why",
      secretAccessKey: "aws",
      sessionToken: "whyyyyy",
    });
    expect(mockSTSClient).toHaveReceivedNthCommandWith(1, AssumeRoleCommand, {
      RoleArn: "foo",
      RoleSessionName: "s3-scan-object",
    });
  });

  test("fails to assume role", async () => {
    mockSTSClient.on(AssumeRoleCommand).rejects(new Error("nope"));
    const credentials = await getRoleCredentials(mockSTSClient, "foo");
    expect(credentials).toBe(null);
  });
});

describe("getS3Client", () => {
  test("successfully gets new client", async () => {
    mockSTSClient.on(AssumeRoleCommand).resolves({ Credentials: { foo: "bar" } });
    const s3Client = await getS3Client(null, mockSTSClient, "bar");
    expect(s3Client).toBeInstanceOf(S3Client);
    expect(mockSTSClient).toHaveReceivedNthCommandWith(1, AssumeRoleCommand, {
      RoleArn: "bar",
      RoleSessionName: "s3-scan-object",
    });
  });

  test("successfully returns cached client", async () => {
    const s3Client = await getS3Client("mellow", mockSTSClient, "bar");
    expect(s3Client).toBe("mellow");
    expect(mockSTSClient.calls().length).toBe(0);
  });
});

describe("getS3ObjectFromRecord", () => {
  test("s3 event", () => {
    const record = {
      s3: {
        bucket: {
          name: "foo",
        },
        object: {
          key: encodeURIComponent("some-folder-path/this is the file name"),
        },
      },
    };
    const expected = {
      Bucket: "foo",
      Key: "some-folder-path/this is the file name",
    };
    expect(getS3ObjectFromRecord("aws:s3", record)).toEqual(expected);
  });

  test("sns event", () => {
    const record = {
      Sns: {
        MessageAttributes: {
          "av-filepath": {
            Value: "s3://bar/bam",
          },
        },
      },
    };
    const expected = {
      Bucket: "bar",
      Key: "bam",
    };
    expect(getS3ObjectFromRecord("aws:sns", record)).toEqual(expected);
  });

  test("recan event", () => {
    const record = {
      s3ObjectUrl: "s3://samwise/gamgee",
    };
    const expected = {
      Bucket: "samwise",
      Key: "gamgee",
    };
    expect(getS3ObjectFromRecord("custom:rescan", record)).toEqual(expected);
  });

  test("sns event, invalid av-filepath", () => {
    const record = {
      Sns: {
        MessageAttributes: {
          "av-filepath": {
            Value: "file:///some.gif",
          },
        },
      },
    };
    expect(getS3ObjectFromRecord("aws:sns", record)).toBe(null);
  });

  test("invalid event", () => {
    expect(getS3ObjectFromRecord("muffins", {})).toBe(null);
  });
});

describe("initConfig", () => {
  test("retrieves the config value", async () => {
    mockSecretManagerClient.on(GetSecretValueCommand).resolvesOnce({
      SecretString: "anotherEquallySecretValue",
    });

    const config = await initConfig();
    expect(config).toEqual({ apiKey: "anotherEquallySecretValue" });
  });

  test("throws an error on failure", async () => {
    mockSecretManagerClient.on(GetSecretValueCommand).rejectsOnce(new Error("nope"));
    await expect(initConfig()).rejects.toThrow("nope");
  });
});

describe("isS3Folder", () => {
  test("identifies folders", () => {
    expect(isS3Folder({ Key: "foobar/" })).toBe(true);
    expect(isS3Folder({ Key: "bam/baz/boom/" })).toBe(true);
  });

  test("identifies things that are not folders", () => {
    expect(isS3Folder(null)).toBe(false);
    expect(isS3Folder(undefined)).toBe(false);
    expect(isS3Folder({ Key: "most-certainly-not-a-folder.png" })).toBe(false);
    expect(isS3Folder({ Key: null })).toBe(false);
    expect(isS3Folder({ Key: undefined })).toBe(false);
    expect(isS3Folder({})).toBe(false);
    expect(isS3Folder({ Key: "" })).toBe(false);
    expect(isS3Folder({ Key: "some/nested/path/with/a/file.txt" })).toBe(false);
  });
});

describe("parseS3Url", () => {
  test("successful parse", async () => {
    expect(parseS3Url("s3://foo/bar")).toEqual({ Bucket: "foo", Key: "bar" });
    expect(parseS3Url("s3://the-spice-must-flow/bar/bam/baz/bing.png")).toEqual({
      Bucket: "the-spice-must-flow",
      Key: "bar/bam/baz/bing.png",
    });
  });

  test("unsuccessful parse", async () => {
    expect(parseS3Url(undefined)).toBe(null);
    expect(parseS3Url(null)).toBe(null);
    expect(parseS3Url("")).toBe(null);
    expect(parseS3Url("s3://foo")).toBe(null);
  });
});

describe("startS3ObjectScan", () => {
  test("starts a scan", async () => {
    axios.post.mockResolvedValueOnce({ status: 200 });
    const response = await startS3ObjectScan(
      "http://somedomain.com",
      "someSuperSecretValue",
      {
        Bucket: "foo",
        Key: "bar",
      },
      "123456789012",
      "someSnsTopicArn",
      "mmmmRequestId"
    );
    expect(response).toEqual({ status: 200 });
    expect(axios.post.mock.calls[0]).toEqual([
      "http://somedomain.com",
      {
        aws_account: "123456789012",
        s3_key: "s3://foo/bar",
        sns_arn: "someSnsTopicArn",
      },
      {
        headers: {
          Accept: "application/json",
          Authorization: "someSuperSecretValue",
          "X-Scanning-Request-Id": "mmmmRequestId",
        },
      },
    ]);
  });

  test("fails to start a scan", async () => {
    axios.post.mockRejectedValueOnce({ response: { status: 500 } });
    const response = await startS3ObjectScan(
      "http://somedomain.com",
      "someSuperSecretValue",
      {
        Bucket: "foo",
        Key: "bar",
      },
      "123456789012",
      "someSnsTopicArn"
    );
    expect(response).toEqual({ status: 500 });
  });
});

describe("tagS3Object", () => {
  test("successfully tags", async () => {
    mockS3Client.on(PutObjectTaggingCommand).resolvesOnce({ VersionId: "yeet" });
    const input = {
      Bucket: "foo",
      Key: "bar",
      Tagging: {
        TagSet: [{ Key: "some-tag", Value: "some-value" }],
      },
    };
    const response = await tagS3Object(mockS3Client, { Bucket: "foo", Key: "bar" }, [
      { Key: "some-tag", Value: "some-value" },
    ]);
    expect(response).toBe(true);
    expect(mockS3Client).toHaveReceivedCommandWith(PutObjectTaggingCommand, input);
  });

  test("fails to tag", async () => {
    mockS3Client.on(PutObjectTaggingCommand).resolvesOnce({});
    const response = await tagS3Object(mockS3Client, {}, []);
    expect(response).toBe(false);
  });
});
