import { REGION, ACCOUNT_NUMBER, DEPLOYMENT_ENVIRONMENT }  from '../constants/index.mjs'

export function generateChatbotLogEvent({ event, messageId }) {
  
  const logEvent = {
    version: "1.0",
    source: "custom",
    id: `ddb-event-${messageId}-${Date.now()}`,
    content: {
      textType: "client-markdown",
      title: getTitle({ event }),
      description: getDescription({ event }),
      keywords: [],
    },
  };

  return logEvent;
}


function getLogType ({ event }) {
  if( event["Event Message"] && event["Event Message"].includes("Started cross AZ failover to DB instance")) {
    return "ERROR"
  }
  
  return "INFO"
}

function getTitle({ event }) {
 return `⚠ AWS DocumentDB Notification | ${REGION} | Account: ${ACCOUNT_NUMBER}`;
}
function getDescription({ event }) {
      return `
>*Event Source*
>${event["Event Source"]}
>*Source ID*
>${event["Source ID"]}
>*Identifier Link*
>${event["Identifier Link"]}
>*Timestamp*
>${event["Event Time"]}
>*Enviornment*
>${DEPLOYMENT_ENVIRONMENT}
_${event["Event Message"]}_
\`\`\`${JSON.stringify(event)}\`\`\`
`;
}