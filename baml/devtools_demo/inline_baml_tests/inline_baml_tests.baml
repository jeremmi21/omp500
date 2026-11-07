function SummarizeShortStory(story: string) -> string {
    client Default
    prompt #"Summarize the following short story in one sentence.
        {{ _.role("user") }}
        <story>
        {{ story }}
        </story>
    "#
}
test short_story_txt {
    functions [SummarizeShortStory]
    args {
        story {
            file "./short_story.txt"
        }
    }
}
