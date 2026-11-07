function InteractiveBamlJupyter_WriteShortStory() -> InteractiveBamlJupyter_ShortStory {
  client "openai/gpt-4.1-nano"
  prompt #"Write a short story about anything  {{ ctx.output_format }}"#
}
class InteractiveBamlJupyter_ShortStory {
    genre string
    characters InteractiveBamlJupyter_Character[] @description(#"at least three characters"#)
    story_summary string @description(#"Short story excerpt about anything, 30 words"#)
}
class InteractiveBamlJupyter_Character {
    name string
    age int
    occupation string
}
test t {
    functions [InteractiveBamlJupyter_WriteShortStory]
    args {}
}

