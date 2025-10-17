# defmodule EventApiWeb.PublicController do
#   use EventApiWeb, :controller

#   alias EventApi.Events
#   alias EventApi.Summaries.Cache
#   alias EventApi.Summaries

#   def index(conn, params) do
#     case Events.list_public_events(params) do
#       %{events: events, pagination: pagination} ->
#         render(conn, :index, events: events, pagination: pagination)
#     end
#   end

#   def summary(conn, %{"id" => id}) do
#     event = Events.get_event!(id)

#     if event.status in ["PUBLISHED", "CANCELLED"] do
#       case Cache.get(event) do
#         {:ok, cached_summary, cache_key} ->
#           conn
#           |> put_resp_header("x-summary-cache", "HIT")
#           |> put_resp_header("x-cache-key", cache_key)
#           |> put_resp_header("cache-control", "public, max-age=3600")
#           |> send_summary_response(cached_summary)

#         {:miss, cache_key} ->
#           # Generate and cache new summary
#           summary = Summaries.generate_summary(event)
#           Cache.put(event, summary)

#           conn
#           |> put_resp_header("x-summary-cache", "MISS")
#           |> put_resp_header("x-cache-key", cache_key)
#           |> put_resp_header("cache-control", "public, max-age=3600")
#           |> send_summary_response(summary)
#       end
#     else
#       conn
#       |> put_status(:not_found)
#       |> put_view(EventApiWeb.ErrorJSON)
#       |> render(:"404")
#     end
#   end

#   def stream_summary(conn, %{"id" => id}) do
#     event = Events.get_event!(id)

#     if event.status in ["PUBLISHED", "CANCELLED"] do
#       # Check cache first to set headers BEFORE send_chunked
#       case Cache.get(event) do
#         {:ok, cached_summary, cache_key} ->
#           # CACHE HIT - Send complete summary immediately
#           conn
#           |> put_resp_header("content-type", "text/event-stream")
#           |> put_resp_header("cache-control", "no-cache")
#           |> put_resp_header("connection", "keep-alive")
#           |> put_resp_header("x-summary-cache", "HIT")
#           |> put_resp_header("x-cache-key", cache_key)
#           |> send_chunked(200)
#           |> chunk("data: #{Jason.encode!(%{chunk: cached_summary, done: true})}\n\n")

#         {:miss, cache_key} ->
#           # CACHE MISS - Stream with chunks
#           conn
#           |> put_resp_header("content-type", "text/event-stream")
#           |> put_resp_header("cache-control", "no-cache")
#           |> put_resp_header("connection", "keep-alive")
#           |> put_resp_header("x-summary-cache", "MISS")
#           |> put_resp_header("x-cache-key", cache_key)
#           |> send_chunked(200)
#           |> stream_summary_chunks(event)
#       end
#     else
#       conn
#       |> put_status(:not_found)
#       |> put_view(EventApiWeb.ErrorJSON)
#       |> render(:"404")
#     end
#   end

#   defp stream_summary_chunks(conn, event) do
#     # Simulate AI processing time for cache miss
#     Process.sleep(500)

#     Summaries.stream_summary_chunks(event)
#     |> Enum.reduce_while(conn, fn chunk_data, conn ->
#       Process.sleep(:rand.uniform(100) + 50)
#       event_data = Jason.encode!(chunk_data)

#       case chunk(conn, "data: #{event_data}\n\n") do
#         {:ok, conn} -> {:cont, conn}
#         {:error, _reason} -> {:halt, conn}
#       end
#     end)
#   end

#   defp send_summary_response(conn, summary) do
#     conn
#     |> put_resp_header("content-type", "application/json")
#     |> json(%{
#       summary: summary,
#       event_id: conn.params["id"],
#       generated_at: DateTime.utc_now()
#     })
#   end
# end

defmodule EventApiWeb.PublicController do
  use EventApiWeb, :controller

  alias EventApi.Events
  alias EventApi.Summaries
  alias EventApi.Summaries.Cache

  @public_statuses ["PUBLISHED", "CANCELLED"]

  @doc """
  List public events with filtering and pagination
  """
  def index(conn, params) do
    case Events.list_public_events(params) do
      %{events: events, pagination: pagination} ->
        render(conn, :index, events: events, pagination: pagination)
    end
  end

  @doc """
  Get cached AI summary for an event
  """
  def summary(conn, %{"id" => id}) do
    with {:ok, event} <- get_public_event(id),
         {:ok, summary, cache_key, cache_status} <-
           generate_or_retrieve_summary(event) do
      conn
      |> put_cache_headers(cache_key, cache_status)
      |> send_summary_response(summary)
    else
      {:error, :not_found} ->
        send_not_found(conn)

      {:error, :not_public} ->
        send_not_found(conn)
    end
  end

  @doc """
  Stream AI summary via Server-Sent Events
  """
  # def stream_summary(conn, %{"id" => id}) do
  #   with {:ok, event} <- get_public_event(id) do
  #     stream_summary_content(conn, event)
  #   else
  #     {:error, :not_found} ->
  #       send_not_found(conn)

  #     {:error, :not_public} ->
  #       send_not_found(conn)
  #   end
  # end
  def stream_summary(conn, %{"id" => id}) do
    case get_public_event(id) do
      {:ok, event} ->
        stream_summary_content(conn, event)

      {:error, _reason} ->
        send_not_found(conn)
    end
  end

  # Private functions

  defp get_public_event(id) do
    case Events.get_event(id) do
      nil ->
        {:error, :not_found}

      event ->
        if event.status in @public_statuses do
          {:ok, event}
        else
          {:error, :not_public}
        end
    end
  end

  defp generate_or_retrieve_summary(event) do
    case Cache.get(event) do
      {:ok, cached_summary, cache_key} ->
        {:ok, cached_summary, cache_key, "HIT"}

      {:miss, cache_key} ->
        summary = Summaries.generate_summary(event)
        Cache.put(event, summary)
        {:ok, summary, cache_key, "MISS"}
    end
  end

  defp stream_summary_content(conn, event) do
    case Cache.get(event) do
      {:ok, cached_summary, cache_key} ->
        # Cache HIT - Send complete summary immediately
        conn
        |> put_sse_headers()
        |> put_cache_headers(cache_key, "HIT")
        |> send_chunked(200)
        |> send_complete_summary(cached_summary)

      {:miss, cache_key} ->
        # Cache MISS - Stream with chunks
        conn
        |> put_sse_headers()
        |> put_cache_headers(cache_key, "MISS")
        |> send_chunked(200)
        |> stream_summary_chunks(event)
    end
  end

  defp put_sse_headers(conn) do
    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> put_resp_header("access-control-allow-origin", "*")
  end

  defp put_cache_headers(conn, cache_key, cache_status) do
    conn
    |> put_resp_header("x-summary-cache", cache_status)
    |> put_resp_header("x-cache-key", cache_key)
    |> put_resp_header("cache-control", "public, max-age=3600")
  end

  defp send_complete_summary(conn, summary) do
    event_data = Jason.encode!(%{chunk: summary, done: true})

    case chunk(conn, "data: #{event_data}\n\n") do
      {:ok, conn} -> conn
      {:error, _reason} -> conn
    end
  end

  defp stream_summary_chunks(conn, event) do
    # Simulate AI processing time for cache miss
    Process.sleep(500)

    Summaries.stream_summary_chunks(event)
    |> Enum.reduce_while(conn, fn chunk_data, conn ->
      # Small random delay to simulate AI processing
      Process.sleep(:rand.uniform(100) + 50)

      event_data = Jason.encode!(chunk_data)

      case chunk(conn, "data: #{event_data}\n\n") do
        {:ok, conn} ->
          {:cont, conn}

        {:error, _reason} ->
          {:halt, conn}
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

  defp send_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(EventApiWeb.ErrorJSON)
    |> render(:"404")
  end
end
