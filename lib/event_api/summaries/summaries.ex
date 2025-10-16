defmodule EventApi.Summaries do
  @moduledoc """
  AI-powered summary generation with streaming capabilities.
  """

  alias EventApi.Events.Event

  @doc """
  Generate a deterministic mock AI summary for an event.
  """
  def generate_summary(%Event{} = event) do
    # Deterministic summary based on event data
    %{
      title: event.title,
      location: event.location,
      start_at: event.start_at,
      status: event.status
    }
    |> build_summary()
  end

  @doc """
  Stream summary in chunks with delays to simulate AI generation.
  """
  def stream_summary_chunks(%Event{} = event) do
    full_summary = generate_summary(event)
    tokens = String.split(full_summary, " ")

    tokens
    |> Enum.chunk_every(3)  # 2-5 tokens per chunk
    |> Enum.with_index()
    |> Enum.map(fn {chunk_tokens, index} ->
      chunk = Enum.join(chunk_tokens, " ")
      %{
        chunk: chunk,
        index: index,
        total: length(tokens) |> div(3) |> max(1),
        done: false
      }
    end)
    |> then(fn chunks ->
      # Mark last chunk as done
      if length(chunks) > 0 do
        List.update_at(chunks, -1, &Map.put(&1, :done, true))
      else
        chunks
      end
    end)
  end

  defp build_summary(%{title: title, location: location, start_at: start_at, status: status}) do
    date_str = if start_at, do: Calendar.strftime(start_at, "%B %d, %Y"), else: "TBA"

    base_summary = """
    Join us for #{title}, happening in #{location} on #{date_str}.
    This is a #{String.downcase(status)} event that promises engaging content and networking opportunities.
    Perfect for professionals looking to connect and learn. Don't miss out - mark your calendar!
    """

    # Ensure 50-100 tokens (words)
    String.split(base_summary, " ")
    |> Enum.take(80)  # Target ~80 tokens
    |> Enum.join(" ")
  end
end
