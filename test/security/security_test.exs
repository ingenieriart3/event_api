defmodule EventApi.SecurityTest do
  use EventApiWeb.ConnCase

  alias EventApi.Events

  @private_attrs %{
    "title" => "Private Event",
    "start_at" => "2024-09-01T10:00:00Z",
    "end_at" => "2024-09-01T12:00:00Z",
    "location" => "Test Location",
    "status" => "PUBLISHED",
    "internal_notes" => "SECRET_INFO",
    "created_by" => "admin@example.com"
  }

  @auth_token "Bearer admin-token-123"

  describe "Security" do
    test "private fields are never exposed in public endpoints", %{conn: conn} do
      # Create event with private fields
      conn = post(conn, ~p"/api/v1/events",
        event: @private_attrs,
        headers: [authorization: @auth_token]
      )

      %{"event" => %{"id" => id}} = json_response(conn, 201)

      # Verify private fields are NOT in public endpoint
      conn = get(conn, ~p"/api/v1/public/events")
      public_events = json_response(conn, 200)["events"]
      public_event = Enum.find(public_events, &(&1["id"] == id))

      refute Map.has_key?(public_event, "internal_notes")
      refute Map.has_key?(public_event, "created_by")
      refute Map.has_key?(public_event, "updated_at")
      refute public_event["internal_notes"] == "SECRET_INFO"
      refute public_event["created_by"] == "admin@example.com"

      # Verify private fields ARE in admin endpoint
      conn = get(conn, ~p"/api/v1/events",
        headers: [authorization: @auth_token]
      )
      admin_events = json_response(conn, 200)["events"]
      admin_event = Enum.find(admin_events, &(&1["id"] == id))

      assert Map.has_key?(admin_event, "internal_notes")
      assert Map.has_key?(admin_event, "created_by")
      assert Map.has_key?(admin_event, "updated_at")
    end

    test "admin endpoints require authentication", %{conn: conn} do
      # POST without auth
      conn = post(conn, ~p"/api/v1/events", event: @private_attrs)
      assert json_response(conn, 401)

      # PATCH without auth
      conn = patch(conn, ~p"/api/v1/events/some-id", event: %{})
      assert json_response(conn, 401)

      # GET without auth
      conn = get(conn, ~p"/api/v1/events")
      assert json_response(conn, 401)

      # Public endpoints work without auth
      conn = get(conn, ~p"/api/v1/public/events")
      assert conn.status == 200
    end

    test "invalid auth token returns 401", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/events",
        headers: [authorization: "Bearer wrong-token"]
      )
      assert json_response(conn, 401)
    end
  end
end
