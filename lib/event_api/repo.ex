defmodule EventApi.Repo do
  use Ecto.Repo,
    otp_app: :event_api,
    adapter: Ecto.Adapters.Postgres
end
