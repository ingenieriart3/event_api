# # # This file is responsible for configuring your application
# # # and its dependencies with the aid of the Config module.
# # #
# # # This configuration file is loaded before any dependency and
# # # is restricted to this project.

# # # General application configuration
# # import Config

# # config :event_api,
# #   ecto_repos: [EventApi.Repo],
# #   generators: [timestamp_type: :utc_datetime, binary_id: true]

# # # Configures the endpoint
# # config :event_api, EventApiWeb.Endpoint,
# #   url: [host: "localhost"],
# #   adapter: Bandit.PhoenixAdapter,
# #   render_errors: [
# #     formats: [json: EventApiWeb.ErrorJSON],
# #     layout: false
# #   ],
# #   pubsub_server: EventApi.PubSub,
# #   live_view: [signing_salt: "j70QjcBw"]

# # # Configures the mailer
# # #
# # # By default it uses the "Local" adapter which stores the emails
# # # locally. You can see the emails in your browser, at "/dev/mailbox".
# # #
# # # For production it's recommended to configure a different adapter
# # # at the `config/runtime.exs`.
# # config :event_api, EventApi.Mailer, adapter: Swoosh.Adapters.Local

# # # Configures Elixir's Logger
# # config :logger, :default_formatter,
# #   format: "$time $metadata[$level] $message\n",
# #   metadata: [:request_id]

# # # Use Jason for JSON parsing in Phoenix
# # config :phoenix, :json_library, Jason

# # # Import environment specific config. This must remain at the bottom
# # # of this file so it overrides the configuration defined above.
# # import_config "#{config_env()}.exs"

# import Config

# config :event_api, EventApi.Repo,
#   database: "event_api_repo",
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost",
#   port: "5432"

# config :event_api,
#   ecto_repos: [EventApi.Repo],
#   static_auth_token: System.get_env("STATIC_AUTH_TOKEN", "dev_token_12345")

# config :event_api, EventApiWeb.Endpoint,
#   url: [host: "localhost"],
#   secret_key_base: "your-secret-key-base-here",
#   render_errors: [
#     formats: [json: EventApiWeb.ErrorJSON],
#     layout: false
#   ],
#   pubsub_server: EventApi.PubSub,
#   live_view: [signing_salt: "your-signing-salt-here"]

# config :logger, :console,
#   format: "$time $metadata[$level] $message\n",
#   metadata: [:request_id]

# config :phoenix, :json_library, Jason

# config :guardian, Guardian,
#   issuer: "event_api",
#   secret_key: "your-guardian-secret-key-here"

# import_config "#{config_env()}.exs"

# config :event_api,
#   static_auth_token: System.get_env("STATIC_AUTH_TOKEN", "dev_token_12345")


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
