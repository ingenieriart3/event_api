defmodule EventApi.EventsTest do
  use EventApi.DataCase

  alias EventApi.Events

  describe "events" do
    alias EventApi.Events.Event

    import EventApi.EventsFixtures

    @invalid_attrs %{status: nil, description: nil, title: nil, location: nil, start_date: nil, end_date: nil, organizer_notes: nil, internal_rating: nil, cost_center: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Events.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Events.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{status: "some status", description: "some description", title: "some title", location: "some location", start_date: ~U[2025-10-15 02:08:00Z], end_date: ~U[2025-10-15 02:08:00Z], organizer_notes: "some organizer_notes", internal_rating: 42, cost_center: "some cost_center"}

      assert {:ok, %Event{} = event} = Events.create_event(valid_attrs)
      assert event.status == "some status"
      assert event.description == "some description"
      assert event.title == "some title"
      assert event.location == "some location"
      assert event.start_date == ~U[2025-10-15 02:08:00Z]
      assert event.end_date == ~U[2025-10-15 02:08:00Z]
      assert event.organizer_notes == "some organizer_notes"
      assert event.internal_rating == 42
      assert event.cost_center == "some cost_center"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      update_attrs = %{status: "some updated status", description: "some updated description", title: "some updated title", location: "some updated location", start_date: ~U[2025-10-16 02:08:00Z], end_date: ~U[2025-10-16 02:08:00Z], organizer_notes: "some updated organizer_notes", internal_rating: 43, cost_center: "some updated cost_center"}

      assert {:ok, %Event{} = event} = Events.update_event(event, update_attrs)
      assert event.status == "some updated status"
      assert event.description == "some updated description"
      assert event.title == "some updated title"
      assert event.location == "some updated location"
      assert event.start_date == ~U[2025-10-16 02:08:00Z]
      assert event.end_date == ~U[2025-10-16 02:08:00Z]
      assert event.organizer_notes == "some updated organizer_notes"
      assert event.internal_rating == 43
      assert event.cost_center == "some updated cost_center"
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event(event, @invalid_attrs)
      assert event == Events.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Events.change_event(event)
    end
  end
end
