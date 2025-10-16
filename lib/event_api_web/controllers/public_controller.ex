# defmodule EventApiWeb.PublicController do
#   use EventApiWeb, :controller

#   alias EventApi.Events
#   alias EventApi.Events.Event
#   alias EventApi.Summaries.Cache
#   alias EventApi.Summaries.Generator

#   def index(conn, params) do
#     events = Events.list_events(params)

#     # Only expose public fields
#     public_events = Enum.map(events, &Event.public_fields/1)

#     render(conn, :index, events: public_events)
#   end

#   def show(conn, %{"id" => id}) do
#     event = Events.get_event!(id)
#     render(conn, :show, event: Event.public_fields(event))
#   end

#   def summary(conn, %{"id" => id}) do
#     event = Events.get_event!(id)

#     # Check cache first
#     case Cache.get(event) do
#       {:ok, cached_summary, cache_key} ->
#         conn
#         |> put_resp_header("x-summary-cache", "hit")
#         |> put_resp_header("x-cache-key", cache_key)
#         |> send_summary_response(cached_summary)

#       {:miss, cache_key} ->
#         # Generate and cache new summary
#         summary = Generator.generate_summary(event)
#         Cache.put(event, summary)

#         conn
#         |> put_resp_header("x-summary-cache", "miss")
#         |> put_resp_header("x-cache-key", cache_key)
#         |> send_summary_response(summary)
#     end
#   end

#   def stream_summary(conn, %{"id" => id}) do
#     event = Events.get_event!(id)

#     conn = conn
#     |> put_resp_header("content-type", "text/event-stream")
#     |> put_resp_header("cache-control", "no-cache")
#     |> put_resp_header("connection", "keep-alive")
#     |> send_chunked(200)

#     # Check cache for immediate response
#     case Cache.get(event) do
#       {:ok, cached_summary, cache_key} ->
#         conn
#         |> put_resp_header("x-summary-cache", "hit")
#         |> put_resp_header("x-cache-key", cache_key)
#         |> chunk("data: #{cached_summary}\n\n")

#       {:miss, cache_key} ->
#         conn = conn
#         |> put_resp_header("x-summary-cache", "miss")
#         |> put_resp_header("x-cache-key", cache_key)

#         # Stream generated summary
#         Generator.stream_summary_chunks(event)
#         |> Enum.reduce_while(conn, fn %{chunk: chunk, index: index, total: total}, conn ->
#           event_data = %{
#             chunk: chunk,
#             index: index,
#             total: total,
#             done: index == total - 1
#           } |> Jason.encode!()

#           case chunk(conn, "data: #{event_data}\n\n") do
#             {:ok, conn} -> {:cont, conn}
#             {:error, _reason} -> {:halt, conn}
#           end
#         end)
#     end

#     conn
#   end

#   defp send_summary_response(conn, summary) do
#     conn
#     |> put_resp_header("content-type", "application/json")
#     |> json(%{summary: summary})
#   end
# end

defmodule EventApiWeb.PublicController do
  use EventApiWeb, :controller

  alias EventApi.Events
  alias EventApi.Events.Event
  alias EventApi.Summaries.Cache
  alias EventApi.Summaries.Generator

  def index(conn, params) do
    case Events.list_public_events(params) do
      %{events: events, pagination: pagination} ->
        render(conn, :index, events: events, pagination: pagination)
    end
  end

  def summary(conn, %{"id" => id}) do
    event = Events.get_event!(id)

    # Only allow access to published or cancelled events
    if event.status in ["PUBLISHED", "CANCELLED"] do
      # Check cache first
      case Cache.get(event) do
        {:ok, cached_summary, cache_key} ->
          conn
          |> put_resp_header("x-summary-cache", "HIT")
          |> put_resp_header("x-cache-key", cache_key)
          |> put_resp_header("cache-control", "public, max-age=3600")
          |> send_summary_response(cached_summary)

        {:miss, cache_key} ->
          # Generate and cache new summary
          summary = Generator.generate_summary(event)
          Cache.put(event, summary)

          conn
          |> put_resp_header("x-summary-cache", "MISS")
          |> put_resp_header("x-cache-key", cache_key)
          |> put_resp_header("cache-control", "public, max-age=3600")
          |> send_summary_response(summary)
      end
    else
      conn
      |> put_status(:not_found)
      |> put_view(EventApiWeb.ErrorJSON)
      |> render(:"404")
    end
  end

  def stream_summary(conn, %{"id" => id}) do
    event = Events.get_event!(id)

    if event.status in ["PUBLISHED", "CANCELLED"] do
      conn = conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> send_chunked(200)

      # Check cache for immediate response
      case Cache.get(event) do
        {:ok, cached_summary, cache_key} ->
          conn
          |> put_resp_header("x-summary-cache", "HIT")
          |> put_resp_header("x-cache-key", cache_key)
          |> chunk("data: #{cached_summary}\n\n")

        {:miss, cache_key} ->
          conn = conn
          |> put_resp_header("x-summary-cache", "MISS")
          |> put_resp_header("x-cache-key", cache_key)

          # Stream generated summary
          Generator.stream_summary_chunks(event)
          |> Enum.reduce_while(conn, fn %{chunk: chunk, index: index, total: total}, conn ->
            event_data = %{
              chunk: chunk,
              index: index,
              total: total,
              done: index == total - 1
            } |> Jason.encode!()

            case chunk(conn, "data: #{event_data}\n\n") do
              {:ok, conn} -> {:cont, conn}
              {:error, _reason} -> {:halt, conn}
            end
          end)
      end

      conn
    else
      conn
      |> put_status(:not_found)
      |> put_view(EventApiWeb.ErrorJSON)
      |> render(:"404")
    end
  end

  defp send_summary_response(conn, summary) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> json(%{summary: summary})
  end
end
