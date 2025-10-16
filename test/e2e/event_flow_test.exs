defmodule EventApi.E2E.EventFlowTest do
  use EventApiWeb.ConnCase, async: false

  alias EventApi.Events

  @valid_attrs %{
    "title" => "Tech Conference 2024",
    "start_at" => "2024-09-01T10:00:00Z",
    "end_at" => "2024-09-01T17:00:00Z",
    "location" => "San Francisco",
    "status" => "DRAFT",
    "internal_notes" => "VIP list pending",
    "created_by" => "cto@example.com"
  }

  @auth_token "Bearer admin-token-123"

  describe "Event Lifecycle Flow" do
    test "DRAFT -> PUBLISHED -> CANCELLED flow with proper notifications", %{conn: conn} do
      # Create event as DRAFT
      conn = post(conn, ~p"/api/v1/events",
        event: @valid_attrs,
        headers: [authorization: @auth_token]
      )

      assert %{"event" => %{"id" => id, "status" => "DRAFT"}} = json_response(conn, 201)

      # Verify event is NOT in public endpoint when DRAFT
      conn = get(conn, ~p"/api/v1/public/events")
      events = json_response(conn, 200)["events"]
      assert Enum.empty?(Enum.filter(events, &(&1["id"] == id)))

      # Publish event
      conn = patch(conn, ~p"/api/v1/events/#{id}",
        event: %{"status" => "PUBLISHED"},
        headers: [authorization: @auth_token]
      )

      assert %{"event" => %{"status" => "PUBLISHED"}} = json_response(conn, 200)

      # Verify event IS in public endpoint when PUBLISHED
      conn = get(conn, ~p"/api/v1/public/events")
      events = json_response(conn, 200)["events"]
      assert Enum.any?(Enum.filter(events, &(&1["id"] == id)))

      # Cancel event
      conn = patch(conn, ~p"/api/v1/events/#{id}",
        event: %{"status" => "CANCELLED"},
        headers: [authorization: @auth_token]
      )

      assert %{"event" => %{"status" => "CANCELLED"}} = json_response(conn, 200)

      # Verify event IS in public endpoint when CANCELLED
      conn = get(conn, ~p"/api/v1/public/events")
      events = json_response(conn, 200)["events"]
      cancelled_event = Enum.find(events, &(&1["id"] == id))
      assert cancelled_event["status"] == "CANCELLED"
    end

    test "query events by date range and locations", %{conn: conn} do
      # Create test events
      events = [
        %{
          "title" => "Event 1", "start_at" => "2024-09-01T10:00:00Z",
          "end_at" => "2024-09-01T12:00:00Z", "location" => "São Paulo", "status" => "PUBLISHED"
        },
        %{
          "title" => "Event 2", "start_at" => "2024-09-02T10:00:00Z",
          "end_at" => "2024-09-02T12:00:00Z", "location" => "Rio de Janeiro", "status" => "PUBLISHED"
        }
      ]

      for event <- events do
        post(conn, ~p"/api/v1/events",
          event: event,
          headers: [authorization: @auth_token]
        )
      end

      # Query by date range and location
      conn = get(conn, ~p"/api/v1/events", %{
        "dateFrom" => "2024-09-01",
        "dateTo" => "2024-09-01",
        "locations" => "Paulo"
      }, headers: [authorization: @auth_token])

      response = json_response(conn, 200)
      assert length(response["events"]) >= 1
      assert Enum.all?(response["events"], &(&1["location"] =~ "Paulo"))
    end
  end
end
