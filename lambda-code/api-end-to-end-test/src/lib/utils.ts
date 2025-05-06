export function generateRandomString(length: number): string {
  const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

  let randomString = "";

  for (let i = 0; i < length; i++) {
    randomString += characters.charAt(Math.floor(Math.random() * characters.length));
  }

  return randomString;
}

export function pause(durationInSeconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, durationInSeconds * 1000));
}
