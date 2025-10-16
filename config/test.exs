import Config

config :event_api, EventApi.Repo,
  username: "event_service_user",
  password: "event_service_password",
  hostname: "localhost",
  # database: "event_service_dev",
  database: "event_api_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :event_api, EventApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
