import consumer from "channels/consumer"

let subscription
export function subscribeChat(conversationId, onMessage) {
  if (subscription) subscription.unsubscribe()
  subscription = consumer.subscriptions.create(
    { channel: "ChatChannel", conversation_id: conversationId || "global" },
    { received(data) { onMessage?.(data) } }
  )
}
consumer.subscriptions.create("ChatChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
  }
});
