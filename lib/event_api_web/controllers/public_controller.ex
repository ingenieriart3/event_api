defmodule EventApiWeb.PublicController do
  use EventApiWeb, :controller

  alias EventApi.Events
  alias EventApi.Summaries.Cache
  alias EventApi.Summaries

  def index(conn, params) do
    case Events.list_public_events(params) do
      %{events: events, pagination: pagination} ->
        render(conn, :index, events: events, pagination: pagination)
    end
  end

  def summary(conn, %{"id" => id}) do
    event = Events.get_event!(id)

    if event.status in ["PUBLISHED", "CANCELLED"] do
      case Cache.get(event) do
        {:ok, cached_summary, cache_key} ->
          conn
          |> put_resp_header("x-summary-cache", "HIT")
          |> put_resp_header("x-cache-key", cache_key)
          |> put_resp_header("cache-control", "public, max-age=3600")
          |> send_summary_response(cached_summary)

        {:miss, cache_key} ->
          # Generate and cache new summary
          summary = Summaries.generate_summary(event)
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
      # Check cache first to set headers BEFORE send_chunked
      case Cache.get(event) do
        {:ok, cached_summary, cache_key} ->
          # CACHE HIT - Send complete summary immediately
          conn
          |> put_resp_header("content-type", "text/event-stream")
          |> put_resp_header("cache-control", "no-cache")
          |> put_resp_header("connection", "keep-alive")
          |> put_resp_header("x-summary-cache", "HIT")
          |> put_resp_header("x-cache-key", cache_key)
          |> send_chunked(200)
          |> chunk("data: #{Jason.encode!(%{chunk: cached_summary, done: true})}\n\n")

        {:miss, cache_key} ->
          # CACHE MISS - Stream with chunks
          conn
          |> put_resp_header("content-type", "text/event-stream")
          |> put_resp_header("cache-control", "no-cache")
          |> put_resp_header("connection", "keep-alive")
          |> put_resp_header("x-summary-cache", "MISS")
          |> put_resp_header("x-cache-key", cache_key)
          |> send_chunked(200)
          |> stream_summary_chunks(event)
      end
    else
      conn
      |> put_status(:not_found)
      |> put_view(EventApiWeb.ErrorJSON)
      |> render(:"404")
    end
  end

  defp stream_summary_chunks(conn, event) do
    # Simulate AI processing time for cache miss
    Process.sleep(500)

    Summaries.stream_summary_chunks(event)
    |> Enum.reduce_while(conn, fn chunk_data, conn ->
      Process.sleep(:rand.uniform(100) + 50)
      event_data = Jason.encode!(chunk_data)

      case chunk(conn, "data: #{event_data}\n\n") do
        {:ok, conn} -> {:cont, conn}
        {:error, _reason} -> {:halt, conn}
      end
    end)
  end

  defp send_summary_response(conn, summary) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> json(%{
      summary: summary,
      event_id: conn.params["id"],
      generated_at: DateTime.utc_now()
    })
  end
end
