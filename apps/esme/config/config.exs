use Mix.Config

config :esme,
  terminate_timeout: 6_000,
  response_limit: 5_000

config :logger, :console,
  format: "\n$time $metadata$message\n",
  metadata: [:role, :pid, :system_id]
