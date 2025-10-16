defmodule EventApi.ValidationTest do
  use EventApiWeb.ConnCase

  @auth_token "Bearer admin-token-123"

  describe "Validation" do
    test "returns validation error for empty title", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/events",
        event: %{
          "title" => "",
          "start_at" => "2024-09-01T10:00:00Z",
          "end_at" => "2024-09-01T12:00:00Z",
          "location" => "Test",
          "status" => "DRAFT"
        },
        headers: [authorization: @auth_token]
      )

      response = json_response(conn, 422)
      assert response["error"]["code"] == "VALIDATION_ERROR"
      assert Enum.any?(response["error"]["details"], &(&1["field"] == "title"))
    end

    test "returns validation error for start date in past", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/events",
        event: %{
          "title" => "Past Event",
          "start_at" => "2020-01-01T10:00:00Z",
          "end_at" => "2024-09-01T12:00:00Z",
          "location" => "Test",
          "status" => "DRAFT"
        },
        headers: [authorization: @auth_token]
      )

      response = json_response(conn, 422)
      assert response["error"]["code"] == "VALIDATION_ERROR"
      assert Enum.any?(response["error"]["details"], &(&1["field"] == "start_at"))
    end

    test "returns validation error for end date before start date", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/events",
        event: %{
          "title" => "Invalid Date Event",
          "start_at" => "2024-09-01T12:00:00Z",
          "end_at" => "2024-09-01T10:00:00Z",
          "location" => "Test",
          "status" => "DRAFT"
        },
        headers: [authorization: @auth_token]
      )

      response = json_response(conn, 422)
      assert response["error"]["code"] == "VALIDATION_ERROR"
      assert Enum.any?(response["error"]["details"], &(&1["field"] == "end_at"))
    end

    test "returns validation error for invalid status transition", %{conn: conn} do
      # Create published event
      conn = post(conn, ~p"/api/v1/events",
        event: %{
          "title" => "Published Event",
          "start_at" => "2024-09-01T10:00:00Z",
          "end_at" => "2024-09-01T12:00:00Z",
          "location" => "Test",
          "status" => "PUBLISHED"
        },
        headers: [authorization: @auth_token]
      )

      %{"event" => %{"id" => id}} = json_response(conn, 201)

      # Try to move back to DRAFT (should fail)
      conn = patch(conn, ~p"/api/v1/events/#{id}",
        event: %{"status" => "DRAFT"},
        headers: [authorization: @auth_token]
      )

      response = json_response(conn, 422)
      assert response["error"]["code"] == "VALIDATION_ERROR"
      assert Enum.any?(response["error"]["details"], &(&1["field"] == "status"))
    end
  end
end
