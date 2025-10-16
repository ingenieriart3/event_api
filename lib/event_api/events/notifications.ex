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
    Logger.info("[NOTIFICATION] New event created: #{event.title}")
    :ok
  end

  @doc """
  Notify when an event is updated.
  """
  def notify_event_updated(%Event{} = event) do
    Logger.info("[NOTIFICATION] Event updated: #{event.title}")
    :ok
  end

  @doc """
  Notify when an event is published.
  """
  def notify_event_published(%Event{} = event) do
    Logger.info("[NOTIFICATION] Event published: #{event.title}")
    :ok
  end

  @doc """
  Notify when an event is cancelled.
  """
  def notify_event_cancelled(%Event{} = event) do
    Logger.info("[NOTIFICATION] Event cancelled: #{event.title}")
    :ok
  end
end
