defmodule EventApiWeb.PublicJSON do
  def index(%{events: events, pagination: pagination}) do
    %{
      events: events,
      pagination: pagination
    }
  end
end
