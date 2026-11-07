class LLMChatMessage {
  role "user" | "assistant"
  content string
}

function ChatWithLLM(messages: LLMChatMessage[]) -> string {
  client Default
  prompt #"
    Answer the user's questions based on the chat history:
    {% for message in messages %}
      {{ _.role(message.role) }} 
      {{ message.content }}
    {% endfor %}

    Answer:
  "#
}
test my_test_1 {
  functions [ChatWithLLM]
  args {
    messages [
      {
        role "user"
        content "What's the weather like?"
      }
    ]
  }
}

test my_test_2 {
  functions [ChatWithLLM]
  args {
    messages [
      {
        role "user"
        content "What's the weather like?"
      },
      {
        role "assistant"
        content "It's sunny."
      },
      {
        role "user"
        content "Do you like sunny weather?"
      }
    ]
  }
}