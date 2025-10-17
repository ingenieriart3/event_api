defmodule EventApi.Summaries.Generator do
  @moduledoc """
  Mock AI-powered summary generator with deterministic output and streaming simulation.
  """
  alias EventApi.Events.Event

  @doc """
  Generate a mock AI summary for an event.
  """
  def generate_summary(%Event{} = event) do
    # Deterministic summary based on event data
    base_summary = """
    Don't miss #{event.title} happening in #{event.location}!
    This incredible event starts on #{format_datetime(event.start_at)}
    and runs until #{format_datetime(event.end_at)}.

    Perfect opportunity to network with industry leaders, learn from expert speakers,
    and discover the latest trends. Whether you're looking to expand your knowledge
    or connect with like-minded professionals, this event has something for everyone.

    Ready to be part of something amazing? Secure your spot now and join us for
    an unforgettable experience at #{event.title}!
    """

    # Simulate token generation (50-100 tokens in chunks of 2-5)
    tokens = String.split(base_summary, " ")
    stream_tokens(tokens, [])
  end

  defp stream_tokens([], acc), do: Enum.reverse(acc) |> Enum.join(" ")

  defp stream_tokens(tokens, acc) do
    chunk_size = Enum.random(2..5)
    {chunk, remaining} = Enum.split(tokens, min(chunk_size, length(tokens)))

    # Simulate AI processing delay
    Process.sleep(Enum.random(50..200))

    stream_tokens(remaining, [Enum.join(chunk, " ") | acc])
  end

  defp format_datetime(datetime) do
    DateTime.to_string(datetime)
  end

  @doc """
  Stream summary chunks for Server-Sent Events.
  """
  def stream_summary_chunks(%Event{} = event) do
    summary = generate_summary(event)

    chunks =
      String.split(summary, ~r/(?<=[.!?])\s+/) |> Enum.filter(&(&1 != ""))

    chunks
    |> Stream.with_index()
    |> Stream.map(fn {chunk, index} ->
      # Simulate streaming delay
      Process.sleep(Enum.random(80..150))
      %{chunk: chunk, index: index, total: length(chunks)}
    end)
  end
end
