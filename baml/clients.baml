// clients.baml — model/client routing for OMP500
// Re-exports config.baml. Agent reads registry.json for skill discovery;
// model routing comes from settings/config.yaml + this file.
// See baml/config.baml for generator + Default client.

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

client<llm> Fallback {
  provider openai
  options {
    model gpt-4.1-mini
    base_url env.OPENAI_API_BASE
  }
}
