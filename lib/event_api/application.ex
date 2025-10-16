# defmodule EventApi.Application do
#   # See https://hexdocs.pm/elixir/Application.html
#   # for more information on OTP Applications
#   @moduledoc false

#   use Application

#   @impl true
#   def start(_type, _args) do
#     children = [
#       EventApiWeb.Telemetry,
#       EventApi.Summaries.Cache,
#       EventApi.Repo,
#       {DNSCluster, query: Application.get_env(:event_api, :dns_cluster_query) || :ignore},
#       {Phoenix.PubSub, name: EventApi.PubSub},
#       # Start a worker by calling: EventApi.Worker.start_link(arg)
#       # {EventApi.Worker, arg},
#       # Start to serve requests, typically the last entry
#       EventApiWeb.Endpoint
#     ]

#     # See https://hexdocs.pm/elixir/Supervisor.html
#     # for other strategies and supported options
#     opts = [strategy: :one_for_one, name: EventApi.Supervisor]
#     Supervisor.start_link(children, opts)
#   end

#   # Tell Phoenix to update the endpoint configuration
#   # whenever the application is updated.
#   @impl true
#   def config_change(changed, _new, removed) do
#     EventApiWeb.Endpoint.config_change(changed, removed)
#     :ok
#   end
# end

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
