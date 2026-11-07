
function BamlCustomTools_GetWeatherInfo(text: string) -> BamlCustomTools_GetWeatherInfo_Parameters {
  client Default
  prompt #"
    {{ text }}
    {{ ctx.output_format }}
  "#
}
class BamlCustomTools_GetWeatherInfo_Parameters {
    city string
    measurement "celsius" | "fahrenheit" @description(#"default: celsius"#)
}
test t {
    functions [BamlCustomTools_GetWeatherInfo]
    args {city "Hi, I'm John from LA"}
}

function BamlCustomTools_GetNextAction(goal: string) -> BamlCustomTools_NextAction {
    client Default
    prompt #"
        Please select the next best action to achieve the goal.
        
        <goal>
        {{ goal }}
        </goal>
        
        {{ ctx.output_format(or_splitter=" OR ", prefix="Answer in JSON format with exactly one next best action:\n") }}
    "#
}
class BamlCustomTools_NextAction {
    @@dynamic
}
