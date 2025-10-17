defmodule EventApiWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.
  """

  # def render(template, _assigns) do
  #   IO.inspect("🔴 ERRORJSON CALLED - Template: #{template} - USING DEFAULT", label: "ERROR_DEBUG")
  #   %{error: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  # end

  def render("404.json", _assigns) do
    %{
      error: %{
        code: "NOT_FOUND",
        message: "Resource not found"
      }
    }
  end

  def render("401.json", _assigns) do
    %{
      error: %{
        code: "UNAUTHORIZED",
        message: "Invalid or missing authentication token"
      }
    }
  end

  def render("422.json", %{changeset: changeset}) do
    IO.inspect("✅ USING 422.json WITH CHANGESET", label: "ERROR_DEBUG")

    %{
      error: %{
        code: "VALIDATION_ERROR",
        message: "Validation failed",
        details: translate_errors(changeset)
      }
    }
  end

  def render("422.json", _assigns) do
    IO.inspect("🟡 USING 422.json WITHOUT CHANGESET", label: "ERROR_DEBUG")

    %{
      error: %{
        code: "VALIDATION_ERROR",
        message: "Validation failed",
        details: []
      }
    }
  end

  def render("400.json", _assigns) do
    %{
      error: %{
        code: "BAD_REQUEST",
        message: "Invalid request parameters"
      }
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {field, messages} ->
      %{
        field: field,
        message: Enum.join(messages, ", ")
      }
    end)
  end
end
