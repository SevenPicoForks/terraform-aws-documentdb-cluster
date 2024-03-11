import { generateChatbotLogEvent } from './functions/generate-chatbot-log-event.mjs';
import { publishToSNSTopic } from './functions/publish-to-sns-topic.mjs';


export const handler = async (event) => {
  const Sns = event.Records?.[0]?.Sns;
  const recordMessage  = Sns?.Message;
  const messageId = Sns?.MessageId;

  if( !recordMessage || !messageId ) {
    throw new Error(`Unable to parse the record and messageId from the following SNS event. ${JSON.stringify(event)} `);
  }

  const ddbEvent = JSON.parse(recordMessage)
  const generatedEvent = generateChatbotLogEvent({ event: ddbEvent, messageId });
  console.log(generatedEvent)
  await publishToSNSTopic(generatedEvent);
  const response = {
    statusCode: 200,
    body: JSON.stringify('Message sent successfully!!'),
  };
  return response;
};
