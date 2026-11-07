// Summarize.baml — Structured-output summarization function.
//
// Demonstrates BAML's typed-output pattern: instead of getting a free-form
// string back, the LLM is constrained to fill a Pydantic-shaped class.

class Summary {
    title string @description("A short, attention-grabbing title (max 12 words)")
    one_line_summary string @description("A single sentence capturing the essence of the text")
    key_points string[] @description("The 3-5 most important takeaways, each one short bullet")
    sentiment "positive" | "negative" | "neutral" | "mixed" @description("Overall emotional tone of the text")
    word_count int @description("Approximate word count of the original input text")
}

function SummarizeText(text: string, max_words: int) -> Summary {
    client Default
    prompt #"
        Summarize the following text in at most {{ max_words }} words.

        Return your answer as JSON matching the `Summary` schema.

        <text>
        {{ text }}
        </text>

        {{ ctx.output_format }}
    "#
}
