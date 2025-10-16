defmodule EventApi.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      EventApi.Repo,

      # Start the Summary Cache GenServer
      EventApi.Summaries.Cache,

      # Start the Telemetry supervisor
      EventApiWeb.Telemetry,

      # Start the PubSub system
      {Phoenix.PubSub, name: EventApi.PubSub},

      # Start the Endpoint (http/https)
      EventApiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: EventApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    EventApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
