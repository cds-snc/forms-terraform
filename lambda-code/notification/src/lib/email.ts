// import AWS from 'aws-sdk';

// const notifyAPI = new AWS.SNS(); // Replace with Notify API client

export const sendNotification = async (emails:string[], subject:string, body:string) => {
  const emailBody = formatContent(body);

  console.log(`Sending notification: emails=${JSON.stringify(emails)}, subject=${subject}, emailBody=${emailBody}`);
  
  // TODO format email body
  // Add Notify API call
};

const formatContent = (body: string) => {
  // add formatting 
  return body;
};
