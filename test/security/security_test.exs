defmodule EventApi.SecurityTest do
  use EventApiWeb.ConnCase

  @future_date "2026-09-01T10:00:00Z"
  @future_end_date "2026-09-01T12:00:00Z"

  @private_attrs %{
    "title" => "Private Event",
    "start_at" => @future_date,
    "end_at" => @future_end_date,
    "location" => "Test Location",
    "status" => "PUBLISHED",
    "internal_notes" => "SECRET_INFO",
    "created_by" => "admin@example.com"
  }

  @auth_token "Bearer admin-token-123"

  describe "Security" do
    test "private fields are never exposed in public endpoints", %{conn: conn} do
      # Create event with private fields
      conn =
        conn
        |> put_req_header("authorization", @auth_token)
        |> post(~p"/api/v1/events", event: @private_attrs)

      %{"event" => %{"id" => id}} = json_response(conn, 201)

      # Verify private fields are NOT in public endpoint
      conn = get(conn, ~p"/api/v1/public/events")
      public_events = json_response(conn, 200)["events"]
      public_event = Enum.find(public_events, &(&1["id"] == id))

      refute Map.has_key?(public_event, "internal_notes")
      refute Map.has_key?(public_event, "created_by")
      refute Map.has_key?(public_event, "updated_at")
      # Estos campos ni siquiera deberían existir
      refute Map.has_key?(public_event, "internal_notes")
      refute Map.has_key?(public_event, "created_by")

      # Verify private fields ARE in admin endpoint
      conn =
        conn
        |> get(~p"/api/v1/events")

      admin_events = json_response(conn, 200)["events"]
      admin_event = Enum.find(admin_events, &(&1["id"] == id))

      assert Map.has_key?(admin_event, "internal_notes")
      assert Map.has_key?(admin_event, "created_by")
      assert Map.has_key?(admin_event, "updated_at")
      assert admin_event["internal_notes"] == "SECRET_INFO"
      assert admin_event["created_by"] == "admin@example.com"
    end

    test "summary endpoints respect event visibility", %{conn: conn} do
      # Create DRAFT event
      conn =
        conn
        |> put_req_header("authorization", @auth_token)
        |> post(~p"/api/v1/events",
          event: %{
            "title" => "Draft Event",
            "start_at" => @future_date,
            "end_at" => @future_end_date,
            "location" => "Test",
            "status" => "DRAFT"
          }
        )

      %{"event" => %{"id" => id}} = json_response(conn, 201)

      # Verify summary endpoints return 404 for DRAFT events
      conn = get(conn, ~p"/api/v1/public/events/#{id}/summary")
      assert json_response(conn, 404)

      conn = get(conn, ~p"/api/v1/public/events/#{id}/summary/stream")
      assert json_response(conn, 404)
    end
  end
end
