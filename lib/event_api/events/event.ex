defmodule EventApi.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(DRAFT PUBLISHED CANCELLED)

  schema "events" do
    # Required fields
    field :title, :string
    field :start_at, :utc_datetime
    field :end_at, :utc_datetime
    field :location, :string
    field :status, :string, default: "DRAFT"

    # Private fields (never exposed publicly)
    field :internal_notes, :string
    field :created_by, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title,
      :start_at,
      :end_at,
      :location,
      :status,
      :internal_notes,
      :created_by
    ])
    |> validate_required([:title, :start_at, :end_at, :location])
    |> validate_length(:title, max: 200)
    |> validate_inclusion(:status, @statuses)
    |> validate_date_range()
    |> validate_start_in_future()
    |> validate_status_transitions(event)
  end

  defp validate_date_range(changeset) do
    start_at = get_field(changeset, :start_at)
    end_at = get_field(changeset, :end_at)

    case {start_at, end_at} do
      {nil, _} ->
        changeset

      {_, nil} ->
        changeset

      {start, end_} when start >= end_ ->
        add_error(changeset, :end_at, "must be after start date")

      _ ->
        changeset
    end
  end

  defp validate_start_in_future(changeset) do
    start_at = get_field(changeset, :start_at)

    case start_at do
      nil ->
        changeset

      start when not is_nil(start) ->
        if DateTime.compare(start, DateTime.utc_now()) == :lt do
          add_error(changeset, :start_at, "must be in the future")
        else
          changeset
        end
    end
  end

  defp validate_status_transitions(changeset, %{status: current_status})
       when not is_nil(current_status) do
    new_status = get_field(changeset, :status)

    cond do
      current_status in ["PUBLISHED", "CANCELLED"] and new_status == "DRAFT" ->
        add_error(
          changeset,
          :status,
          "cannot move from #{current_status} back to DRAFT"
        )

      true ->
        changeset
    end
  end

  defp validate_status_transitions(changeset, _), do: changeset

  @doc """
  Returns public fields only for public API exposure
  """
  def public_fields(%__MODULE__{} = event) do
    %{
      id: event.id,
      title: event.title,
      start_at: event.start_at,
      end_at: event.end_at,
      location: event.location,
      status: event.status
      # is_upcoming: is_upcoming?(event)
    }
  end

  @doc """
  Check if an event is upcoming (start date is in the future)
  """
  def is_upcoming?(%{start_at: start_at}) when not is_nil(start_at) do
    DateTime.compare(start_at, DateTime.utc_now()) == :gt
  end

  def is_upcoming?(_), do: false
end
