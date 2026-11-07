function SummarizeAction(action: string, result: string) -> string {
    client Default
    prompt #"Give precise one-liner to describe the action.
      Examples:
      - Searched the web for Bitcoin price ($45,399)
      - Acquired for weather information in Paris (24C, sunny)
      <action>
      {{action}}
      </action>
      <result>
      {{result}}
      </result>
    "#
}
test t {
    functions [SummarizeAction]
    args {action #"{
      "action_id": "get_weather",
      "city": "Paris",
      "unit": "celsius"
    }"#}
}

