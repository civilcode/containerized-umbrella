use Mix.Config

# Configure your database
config :containerized, Containerized.Repo,
  username: "postgres",
  password: "postgres",
  database: "containerized_test",
  hostname: "db",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :containerized_web, ContainerizedWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
