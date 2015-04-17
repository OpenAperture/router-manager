use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :router_manager, RouterManager.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :router_manager, RouterManager.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "router_manager_test",
  size: 1,
  max_overflow: false
