defmodule EventApiWeb.PublicEventJSON do
  alias EventApi.Events.Event

  def index(%{events: events, pagination: pagination}) do
    %{
      events: Enum.map(events, &public_event_data/1),
      pagination: pagination
    }
  end

  defp public_event_data(%Event{} = event) do
    Event.public_fields(event)
  end
end
