function GetNextAction(goal: string, interactions: Interaction[]) -> NextAction {
    client Default
    prompt #"
        Please select the next best action to achieve the goal.
        
        <goal>
        {{ goal }}
        </goal>
        
        {{ ctx.output_format(or_splitter=" OR ", prefix="Answer in JSON format with exactly one next best action:\n") }}

        {% for k in interactions %}
        {{ _.role("assistant") }}
        {{ k.action }}
        {{ _.role("user") }}
        {% if k.result.error %}
        Your chosen action did not succeed. Details:
        {% endif %}
        {{ k.result.content }}
        {% endfor %}
    "#
}
class NextAction {
    @@dynamic
}
class Interaction {
    action string
    result Result
}
class Result {
    content string
    error bool
}

