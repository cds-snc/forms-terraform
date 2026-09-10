import type { Attachment } from "../../src/lib/attachments.ts";

export const searchForAttachmentsInResponsesTestData: { responses: Record<string, unknown>; expectedAttachments: Attachment[] }[] = [
  {
    responses: {
      "2": "dsqd",
      "3": "dqsdsq",
      "4": "Opt 2",
      "5": ["Check 1"],
      "6": "D 2",
      "7": "S 2",
      "8": ["Condition 1", "Condition 2", "Condition 3"],
      "9": { id: "1d12c44d-fd88-4861-a3c5-f0accbc504ae", name: "Screenshot 2026-07-22 at 1.44.13 PM.png", size: 248620 },
      "10": { id: "23eae54b-3d87-469f-908e-0e5857d177f5", name: "Screenshot 2026-08-05 at 12.10.07 PM.png", size: 49178 },
      "11": "12121",
      "12": [
        { "0": "dqsdsq", "1": { id: "5d418c6d-bdea-4bb8-962e-e9b5dac3e1b3", name: "Screenshot 2026-07-09 at 10.48.38 AM.png", size: 29028 }, "3": "5147865867", "4": "allo@test.com", "5": "English" },
        { "0": "dsqd", "1": { id: "4294fcb1-702b-4a06-bd83-d0d7cbdc5e76", name: "Screenshot 2026-07-29 at 1.21.19 PM.png", size: 13272 }, "3": "5149876985", "4": "cl@test.com", "5": "French" },
      ],
      "13": { value: 4, numberOfStars: 8 },
      "14": { id: "c28d9f78-f117-4996-9e0f-37374b1679e5", name: "Screenshot 2026-05-08 at 10.46.41 AM.png", size: 621040 },
      "15": [
        {
          "0": "Opt 1",
          "1": { streetAddress: "114-150 Av De Navarre", city: "Saint-Lambert", province: "Québec", postalCode: "J4S 1R6", country: "Canada" },
          "2": { id: "920a99f4-8d2f-461e-9766-a8c963433b4a", name: "!@#$%^&()[]{},.;'\"+=~\\%?.png", size: 914108 },
          "1-streetAddress": "114-150 Av De Navarre, Saint-Lambert, QC, J4S 1R6",
        },
        {
          "0": "Opt 2",
          "1": { streetAddress: "115-1000 Glenhaven Way", city: "Cochrane", province: "Alberta", postalCode: "T4C 1Y9", country: "Canada" },
          "2": { id: "a4e63e00-14ab-44bf-9121-50f93496097d", name: "Scréènshot 2026-06-30 at 9.23.49 AM.png", size: 131493 },
          "1-streetAddress": "115-1000 Glenhaven Way, Cochrane, AB, T4C 1Y9",
        },
        {
          "0": "Opt 1",
          "1": { streetAddress: "123-160 Tycos Dr", city: "North York", province: "Ontario", postalCode: "M6B 1W8", country: "Canada" },
          "2": { id: "7e36e809-d8c3-40a9-85c4-bf5fa9f37a3d", name: "Screenshot 2026-05-08 at 10.46.41 AM.png", size: 621040 },
          "1-streetAddress": "123-160 Tycos Dr, North York, ON, M6B 1W8",
        },
      ],
    },
    expectedAttachments: [
      {
        id: "1d12c44d-fd88-4861-a3c5-f0accbc504ae",
        name: "Screenshot 2026-07-22 at 1.44.13 PM.png",
        size: 248620,
      },
      {
        id: "23eae54b-3d87-469f-908e-0e5857d177f5",
        name: "Screenshot 2026-08-05 at 12.10.07 PM.png",
        size: 49178,
      },
      {
        id: "5d418c6d-bdea-4bb8-962e-e9b5dac3e1b3",
        name: "Screenshot 2026-07-09 at 10.48.38 AM.png",
        size: 29028,
      },
      {
        id: "4294fcb1-702b-4a06-bd83-d0d7cbdc5e76",
        name: "Screenshot 2026-07-29 at 1.21.19 PM.png",
        size: 13272,
      },
      {
        id: "c28d9f78-f117-4996-9e0f-37374b1679e5",
        name: "Screenshot 2026-05-08 at 10.46.41 AM.png",
        size: 621040,
      },
      {
        id: "920a99f4-8d2f-461e-9766-a8c963433b4a",
        name: "!@#$%^&()[]{},.;'\"+=~\\%?.png",
        size: 914108,
      },
      {
        id: "a4e63e00-14ab-44bf-9121-50f93496097d",
        name: "Scréènshot 2026-06-30 at 9.23.49 AM.png",
        size: 131493,
      },
      {
        id: "7e36e809-d8c3-40a9-85c4-bf5fa9f37a3d",
        name: "Screenshot 2026-05-08 at 10.46.41 AM.png",
        size: 621040,
      },
    ],
  },
];
