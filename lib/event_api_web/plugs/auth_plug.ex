defmodule EventApiWeb.AuthPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    token = get_req_header(conn, "authorization") |> List.first()

    case token do
      "Bearer " <> provided_token ->
        static_token =
          Application.get_env(:event_api, :static_auth_token, "admin-token-123")

        if provided_token == static_token do
          conn
        else
          conn
          |> put_status(:unauthorized)
          |> put_resp_content_type("application/json")
          |> send_resp(:unauthorized, ~s({"error": "Unauthorized"}))
          |> halt()
        end

      _ ->
        conn
        |> put_status(:unauthorized)
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, ~s({"error": "Unauthorized"}))
        |> halt()
    end
  end
end
