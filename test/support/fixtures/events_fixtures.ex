defmodule EventApi.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EventApi.Events` context.
  """

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        cost_center: "some cost_center",
        description: "some description",
        end_date: ~U[2025-10-15 02:08:00Z],
        internal_rating: 42,
        location: "some location",
        organizer_notes: "some organizer_notes",
        start_date: ~U[2025-10-15 02:08:00Z],
        status: "some status",
        title: "some title"
      })
      |> EventApi.Events.create_event()

    event
  end
end
