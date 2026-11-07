generator target {
    output_type "python/pydantic"
    output_dir ".."
    version "0.226.2"
    default_client_mode sync
}

client<llm> Default {
  provider openai
  options {
    model gpt-4.1
    base_url env.OPENAI_API_BASE
  }
}
