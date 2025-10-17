import Config

config :event_api, EventApi.Repo,
  username: "event_service_user",
  password: "event_service_password",
  hostname: "localhost",
  database: "event_service_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :event_api, EventApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base:
    "supersecretkey1234567890supersecretkey1234567890supersecretkey1234567890",
  watchers: []

config :event_api, :dev_routes, true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
