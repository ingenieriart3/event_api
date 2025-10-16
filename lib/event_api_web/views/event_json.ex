defmodule EventApiWeb.EventJSON do
  alias EventApi.Events.Event

  def index(%{events: events, pagination: pagination}) do
    %{
      events: Enum.map(events, &event_data/1),
      pagination: pagination
    }
  end

  def show(%{event: event}) do
    %{event: event_data(event)}
  end

  defp event_data(%Event{} = event) do
    %{
      id: event.id,
      title: event.title,
      start_at: event.start_at,
      end_at: event.end_at,
      location: event.location,
      status: event.status,
      internal_notes: event.internal_notes,
      created_by: event.created_by,
      updated_at: event.updated_at,
      inserted_at: event.inserted_at
    }
  end
end
