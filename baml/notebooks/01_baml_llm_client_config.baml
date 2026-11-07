class LLMClientConfig_ExtractedCity {
    city string @description(#"Unabbreviated city name without the state"#)
}

function LLMClientConfig_ExtractCity(text: string) -> LLMClientConfig_ExtractedCity {
  client "openai/gpt-4.1-nano"
  prompt #"
    Extract: 
    "{{ text }}". 
    {{ ctx.output_format }}
  "#
}

test t {
    functions [LLMClientConfig_ExtractCity]
    args {text "Hi, I'm John from LA"}
}

