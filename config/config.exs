import Config

config :event_api,
  ecto_repos: [EventApi.Repo],
  static_auth_token: System.get_env("STATIC_AUTH_TOKEN", "admin-token-123")

config :event_api, EventApiWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: EventApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EventApi.PubSub,
  live_view: [signing_salt: "your-signing-salt-here"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
