# defmodule EventApiWeb.EventController do
#   use EventApiWeb, :controller

#   alias EventApi.Events
#   alias EventApi.Events.Event

#   action_fallback EventApiWeb.FallbackController

#   plug :authenticate when action in [:index, :create, :update]

#   def index(conn, params) do
#     events = Events.list_events(params)
#     render(conn, :index, events: events)
#   end

#   def create(conn, %{"event" => event_params}) do
#     with {:ok, %Event{} = event} <- Events.create_event(event_params) do
#       conn
#       |> put_status(:created)
#       |> put_resp_header("location", ~p"/api/events/#{event}")
#       |> render(:show, event: event)
#     end
#   end

#   def update(conn, %{"id" => id, "event" => event_params}) do
#     event = Events.get_event!(id)

#     with {:ok, %Event{} = event} <- Events.update_event(event, event_params) do
#       render(conn, :show, event: event)
#     end
#   end

#   defp authenticate(conn, _opts) do
#     token = get_req_header(conn, "authorization") |> List.first()

#     case token do
#       "Bearer " <> provided_token ->
#         static_token = Application.get_env(:event_api, :static_auth_token, "dev_token_12345")

#         if provided_token == static_token do
#           conn
#         else
#           conn
#           |> put_status(:unauthorized)
#           |> put_view(EventApiWeb.ErrorJSON)
#           |> render(:"401")
#           |> halt()
#         end
#       _ ->
#         conn
#         |> put_status(:unauthorized)
#         |> put_view(EventApiWeb.ErrorJSON)
#         |> render(:"401")
#           |> halt()
#     end
#   end
# end

defmodule EventApiWeb.EventController do
  use EventApiWeb, :controller

  alias EventApi.Events
  alias EventApi.Events.Event

  action_fallback EventApiWeb.FallbackController

  plug :authenticate when action in [:index, :create, :update]

  def index(conn, params) do
    case Events.list_events(params) do
      %{events: events, pagination: pagination} ->
        render(conn, :index, events: events, pagination: pagination)
    end
  end

  def create(conn, %{"event" => event_params}) do
    with {:ok, %Event{} = event} <- Events.create_event(event_params) do
      conn
      |> put_status(:created)
      |> render(:show, event: event)
    end
  end

  def update(conn, %{"id" => id, "event" => event_params}) do
    event = Events.get_event!(id)

    with {:ok, %Event{} = event} <- Events.update_event(event, event_params) do
      render(conn, :show, event: event)
    end
  end

  defp authenticate(conn, _opts) do
    token = get_req_header(conn, "authorization") |> List.first()

    case token do
      "Bearer " <> provided_token ->
        static_token = Application.get_env(:event_api, :static_auth_token, "admin-token-123")

        if provided_token == static_token do
          conn
        else
          conn
          |> put_status(:unauthorized)
          |> put_view(EventApiWeb.ErrorJSON)
          |> render(:"401")
          |> halt()
        end
      _ ->
        conn
        |> put_status(:unauthorized)
        |> put_view(EventApiWeb.ErrorJSON)
        |> render(:"401")
        |> halt()
    end
  end
end
