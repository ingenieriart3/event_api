defmodule EventApiWeb.FallbackController do
  use EventApiWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(EventApiWeb.ErrorJSON)
    # ← Asegurar que pasa el changeset
    |> render("422.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(EventApiWeb.ErrorJSON)
    |> render("404.json")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(EventApiWeb.ErrorJSON)
    |> render("401.json")
  end

  def call(conn, {:error, :forbidden_fields}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(EventApiWeb.ErrorJSON)
    |> render("422.json", %{
      changeset: %Ecto.Changeset{
        errors: [base: {"Only status and internal_notes can be updated", []}],
        valid?: false
      }
    })
  end

  def call(conn, {:error, :invalid_token}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(EventApiWeb.ErrorJSON)
    |> render("401.json")
  end

  # Capturar cualquier otro error 422
  def call(conn, {:error, _reason}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(EventApiWeb.ErrorJSON)
    |> render("422.json")
  end
end
