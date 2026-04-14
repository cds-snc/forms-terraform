import axios from "axios";

export async function sendToSlack(group: string, message: string, level: string): Promise<void> {
  const logLevelThemeForSlack = logLevelAsEmojiAndColor(level);

  try {
    if (process.env.SLACK_WEBHOOK === undefined) {
      throw new Error("SLACK_WEBHOOK is undefined");
    }

    await axios.post(process.env.SLACK_WEBHOOK, {
      attachments: [
        {
          color: logLevelThemeForSlack.color,
          blocks: [
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: `${logLevelThemeForSlack.emoji} *${group}*`,
              },
            },
            {
              type: "divider",
            },
            {
              type: "section",
              text: {
                type: "plain_text",
                text: message,
              },
            },
          ],
        },
      ],
    });
  } catch (error) {
    console.error(`Slack API call failed. Reason ${(error as Error).message}`);

    throw error;
  }
}

function logLevelAsEmojiAndColor(emojiLevel: string): { emoji: string; color: string } {
  switch (emojiLevel) {
    case "danger":
    case "error":
    case "SEV1":
    case "SEV2":
      return { emoji: ":rotating_light:", color: "#eb1607" };
    case "warning":
    case "warn":
      return { emoji: ":warning:", color: "#f29c3a" };
    default:
      return { emoji: ":loudspeaker:", color: "#0ac73f" };
  }
}
