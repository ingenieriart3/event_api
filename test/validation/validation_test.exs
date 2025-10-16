defmodule EventApi.ValidationTest do
  use EventApiWeb.ConnCase

  @auth_token "Bearer admin-token-123"
  @future_date "2026-09-01T10:00:00Z"
  @future_end_date "2026-09-01T12:00:00Z"

  describe "Validation" do
    test "returns validation error for empty title", %{conn: conn} do
      conn = conn
      |> put_req_header("authorization", @auth_token)
      |> post(~p"/api/v1/events", event: %{
        "title" => "",
        "start_at" => @future_date,
        "end_at" => @future_end_date,
        "location" => "Test",
        "status" => "DRAFT"
      })

      response = json_response(conn, 422)
      assert response["error"]["code"] == "VALIDATION_ERROR"
      assert Enum.any?(response["error"]["details"], &(&1["field"] == "title"))
    end

    test "returns validation error for start date in past", %{conn: conn} do
      conn = conn
      |> put_req_header("authorization", @auth_token)
      |> post(~p"/api/v1/events", event: %{
        "title" => "Past Event",
        "start_at" => "2020-01-01T10:00:00Z",
        "end_at" => @future_end_date,
        "location" => "Test",
        "status" => "DRAFT"
      })

      response = json_response(conn, 422)
      assert response["error"]["code"] == "VALIDATION_ERROR"
      assert Enum.any?(response["error"]["details"], &(&1["field"] == "start_at"))
    end

    test "returns validation error for end date before start date", %{conn: conn} do
      conn = conn
      |> put_req_header("authorization", @auth_token)
      |> post(~p"/api/v1/events", event: %{
        "title" => "Invalid Date Event",
        "start_at" => @future_date,
        "end_at" => "2020-01-01T10:00:00Z",  # Fecha anterior
        "location" => "Test",
        "status" => "DRAFT"
      })

      response = json_response(conn, 422)
      assert response["error"]["code"] == "VALIDATION_ERROR"
      assert Enum.any?(response["error"]["details"], &(&1["field"] == "end_at"))
    end

    test "returns validation error for invalid status transition", %{conn: conn} do
      # Create published event
      conn = conn
      |> put_req_header("authorization", @auth_token)
      |> post(~p"/api/v1/events", event: %{
        "title" => "Published Event",
        "start_at" => @future_date,
        "end_at" => @future_end_date,
        "location" => "Test",
        "status" => "PUBLISHED"
      })

      %{"event" => %{"id" => id}} = json_response(conn, 201)

      # Try to move back to DRAFT (should fail)
      conn = conn
      |> patch(~p"/api/v1/events/#{id}", event: %{"status" => "DRAFT"})

      response = json_response(conn, 422)
      assert response["error"]["code"] == "VALIDATION_ERROR"
      assert Enum.any?(response["error"]["details"], &(&1["field"] == "status"))
    end

    test "returns validation error for updating forbidden fields", %{conn: conn} do
      # Create event
      conn = conn
      |> put_req_header("authorization", @auth_token)
      |> post(~p"/api/v1/events", event: %{
        "title" => "Test Event",
        "start_at" => @future_date,
        "end_at" => @future_end_date,
        "location" => "Test",
        "status" => "DRAFT"
      })

      %{"event" => %{"id" => id}} = json_response(conn, 201)

      # Try to update forbidden field (title)
      conn = conn
      |> patch(~p"/api/v1/events/#{id}", event: %{"title" => "Modified Title", "status" => "PUBLISHED"})

      response = json_response(conn, 422)
      assert response["error"]["code"] == "VALIDATION_ERROR"
      assert Enum.any?(response["error"]["details"], &(&1["field"] == "base"))
    end
  end
end
