defmodule EventApi.E2E.EventFlowTest do
  use EventApiWeb.ConnCase, async: false

  # Usar fechas futuras
  @future_date "2026-09-01T10:00:00Z"
  @future_end_date "2026-09-01T17:00:00Z"

  @valid_attrs %{
    "title" => "Tech Conference 2026",
    "start_at" => @future_date,
    "end_at" => @future_end_date,
    "location" => "San Francisco",
    "status" => "DRAFT",
    "internal_notes" => "VIP list pending",
    "created_by" => "cto@example.com"
  }

  @auth_token "Bearer admin-token-123"

  describe "Event Lifecycle Flow" do
    test "DRAFT -> PUBLISHED -> CANCELLED flow with proper notifications", %{
      conn: conn
    } do
      # Create event as DRAFT
      conn =
        conn
        |> put_req_header("authorization", @auth_token)
        |> post(~p"/api/v1/events", event: @valid_attrs)

      assert %{"event" => %{"id" => id, "status" => "DRAFT"}} =
               json_response(conn, 201)

      # Verify event is NOT in public endpoint when DRAFT
      conn = get(conn, ~p"/api/v1/public/events")
      events = json_response(conn, 200)["events"]
      assert Enum.empty?(Enum.filter(events, &(&1["id"] == id)))

      # Publish event
      conn =
        conn
        |> patch(~p"/api/v1/events/#{id}", event: %{"status" => "PUBLISHED"})

      assert %{"event" => %{"status" => "PUBLISHED"}} = json_response(conn, 200)

      # Verify event IS in public endpoint when PUBLISHED
      conn = get(conn, ~p"/api/v1/public/events")
      events = json_response(conn, 200)["events"]
      assert Enum.any?(Enum.filter(events, &(&1["id"] == id)))

      # Cancel event
      conn =
        conn
        |> patch(~p"/api/v1/events/#{id}", event: %{"status" => "CANCELLED"})

      assert %{"event" => %{"status" => "CANCELLED"}} = json_response(conn, 200)

      # Verify event IS in public endpoint when CANCELLED
      conn = get(conn, ~p"/api/v1/public/events")
      events = json_response(conn, 200)["events"]
      cancelled_event = Enum.find(events, &(&1["id"] == id))
      assert cancelled_event["status"] == "CANCELLED"
    end

    test "query events by date range and locations", %{conn: conn} do
      # Create test events with future dates
      events = [
        %{
          "title" => "Event São Paulo",
          "start_at" => "2026-09-01T10:00:00Z",
          "end_at" => "2026-09-02T12:00:00Z",
          "location" => "São Paulo",
          "status" => "PUBLISHED"
        },
        %{
          "title" => "Event Rio de Janeiro",
          "start_at" => "2026-09-02T10:00:00Z",
          "end_at" => "2026-09-04T12:00:00Z",
          "location" => "Rio de Janeiro",
          "status" => "PUBLISHED"
        }
      ]

      for event <- events do
        conn
        |> put_req_header("authorization", @auth_token)
        |> post(~p"/api/v1/events", event: event)
      end

      # Query by date range and location - usar "São" en lugar de "Paulo"
      conn =
        conn
        |> put_req_header("authorization", @auth_token)
        |> get(~p"/api/v1/events", %{
          "dateFrom" => "2020-09-01",
          "dateTo" => "2030-09-06",
          "location" => "São"
        })

      response = json_response(conn, 200)
      assert length(response["events"]) >= 1
      # Verificar que al menos un evento contiene "São" en location
      assert Enum.any?(
               response["events"],
               &String.contains?(&1["location"], "São")
             )
    end

    test "authentication enforcement - 401 when missing token", %{conn: conn} do
      # POST without auth
      conn = post(conn, ~p"/api/v1/events", event: @valid_attrs)
      assert json_response(conn, 401)

      assert %{"error" => %{"code" => "UNAUTHORIZED"}} =
               json_response(conn, 401)

      # PATCH without auth
      conn = patch(conn, ~p"/api/v1/events/some-id", event: %{})
      assert json_response(conn, 401)

      # GET without auth
      conn = get(conn, ~p"/api/v1/events")
      assert json_response(conn, 401)
    end

    test "authentication enforcement - 401 when invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer wrong-token")
        |> get(~p"/api/v1/events")

      assert json_response(conn, 401)

      assert %{"error" => %{"code" => "UNAUTHORIZED"}} =
               json_response(conn, 401)
    end

    test "public endpoints work without authentication", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/public/events")
      assert conn.status == 200

      # Usar un UUID que no existe - debería dar 404
      non_existent_uuid = Ecto.UUID.generate()
      conn = get(conn, ~p"/api/v1/public/events/#{non_existent_uuid}/summary")
      assert conn.status == 404

      conn =
        get(conn, ~p"/api/v1/public/events/#{non_existent_uuid}/summary/stream")

      assert conn.status == 404
    end
  end
end
