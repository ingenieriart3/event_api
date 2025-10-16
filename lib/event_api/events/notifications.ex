defmodule EventApi.Events.Notifications do
  @moduledoc """
  Mock notification service for event lifecycle events.
  """
  require Logger

  alias EventApi.Events.Event

  @doc """
  Notify when an event is created.
  """
  def notify_event_created(%Event{} = event) do
    Logger.info("""
    [NOTIFICATION] Event CREATED:
    - Title: #{event.title}
    - ID: #{event.id}
    - Status: #{event.status}
    - Starts: #{format_datetime(event.start_at)}
    - Location: #{event.location}
    - Created by: #{event.created_by || "N/A"}
    """)
    :ok
  end

  @doc """
  Notify when an event is updated.
  """
  def notify_event_updated(%Event{} = event) do
    Logger.info("""
    [NOTIFICATION] Event UPDATED:
    - Title: #{event.title}
    - ID: #{event.id}
    - Status: #{event.status}
    - Internal Notes: #{if event.internal_notes, do: "updated", else: "none"}
    """)
    :ok
  end

  @doc """
  Notify when an event is published.
  """
  def notify_event_published(%Event{} = event) do
    Logger.info("""
    [NOTIFICATION] Event PUBLISHED:
    - Title: #{event.title}
    - ID: #{event.id}
    - Starts: #{format_datetime(event.start_at)}
    - Location: #{event.location}
    - Is Upcoming: #{Event.is_upcoming?(event)}
    """)
    :ok
  end

  @doc """
  Notify when an event is cancelled.
  """
  def notify_event_cancelled(%Event{} = event) do
    cancellation_reason = if event.internal_notes, do: " - Reason: #{event.internal_notes}", else: ""

    Logger.info("""
    [NOTIFICATION] Event CANCELLED:
    - Title: #{event.title}
    - ID: #{event.id}
    - Was scheduled for: #{format_datetime(event.start_at)}
    - Location: #{event.location}#{cancellation_reason}
    """)
    :ok
  end

  @doc """
  Notify when an event is re-published (from CANCELLED to PUBLISHED).
  """
  def notify_event_republished(%Event{} = event) do
    Logger.info("""
    [NOTIFICATION] Event RE-PUBLISHED:
    - Title: #{event.title}
    - ID: #{event.id}
    - Was previously cancelled, now published again
    - Starts: #{format_datetime(event.start_at)}
    - Location: #{event.location}
    """)
    :ok
  end

  defp format_datetime(nil), do: "N/A"
  defp format_datetime(datetime) do
    DateTime.to_iso8601(datetime)
  end
end
