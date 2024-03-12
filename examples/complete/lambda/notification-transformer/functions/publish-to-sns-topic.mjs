import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

import { SNS_TOPIC_ARN, REGION } from '../constants/index.mjs';

const snsClient = new SNSClient({
  region: REGION,
});

export async function publishToSNSTopic (message) {
  const TopicArn=SNS_TOPIC_ARN;
  const messageString = JSON.stringify(message);
  const params = {
    TopicArn,
    Message: messageString
  };

  const publishCommand = new PublishCommand(params);

  try {
    const data = await snsClient.send(publishCommand);
    console.log("Message published to SNS successfully:", messageString);
    return data;
  } catch (err) {
    console.error("Error publishing message to SNS:", err);
    throw err;
  }
};
