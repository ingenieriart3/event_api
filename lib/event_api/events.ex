defmodule EventApi.Events do
  import Ecto.Query, warn: false
  alias EventApi.Repo
  alias EventApi.Events.Event
  alias EventApi.Events.Notifications

  @doc """
  Returns paginated list of events with filtering
  """
  def list_events(params \\ %{}) do
    page = String.to_integer(Map.get(params, "page", "1"))
    limit = String.to_integer(Map.get(params, "limit", "20")) |> min(100)
    offset = (page - 1) * limit

    base_query = from(e in Event)

    query =
      base_query
      |> apply_date_filter(params)
      |> apply_location_filter(params)
      |> apply_status_filter(params)
      |> order_by([e], asc: e.start_at)

    total = Repo.aggregate(query, :count)
    events = query |> offset(^offset) |> limit(^limit) |> Repo.all()

    %{
      events: events,
      pagination: %{
        page: page,
        limit: limit,
        total: total,
        total_pages: ceil(total / limit)
      }
    }
  end

  defp apply_date_filter(query, %{"dateFrom" => date_from, "dateTo" => date_to}) do
    # CORRECCIÓN: Usar NaiveDateTime.new! correctamente
    start_date = NaiveDateTime.new!(Date.from_iso8601!(date_from), ~T[00:00:00])
    end_date = NaiveDateTime.new!(Date.from_iso8601!(date_to), ~T[23:59:59])

    where(query, [e], e.start_at >= ^start_date and e.end_at <= ^end_date)
  end

  defp apply_date_filter(query, _), do: query

  defp apply_location_filter(query, %{"locations" => locations}) do
    location_list = String.split(locations, ",") |> Enum.map(&String.trim/1)

    query
    |> where([e], fragment("LOWER(?) LIKE ANY(?)", e.location, ^location_list))
  end

  defp apply_location_filter(query, _), do: query

  defp apply_status_filter(query, %{"status" => status}) do
    status_list = String.split(status, ",") |> Enum.map(&String.trim/1)
    where(query, [e], e.status in ^status_list)
  end

  defp apply_status_filter(query, _), do: query

  @doc """
  Gets a single event.
  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates an event.
  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, event} ->
        Notifications.notify_event_created(event)
        {:ok, event}
      error -> error
    end
  end

  @doc """
  Updates an event (only status and internal_notes allowed).
  """
  def update_event(%Event{} = event, attrs) do
    old_fields = %{
      title: event.title,
      location: event.location,
      start_at: event.start_at,
      end_at: event.end_at
    }

    # Only allow status and internal_notes updates
    update_attrs = Map.take(attrs, ["status", "internal_notes"])

    event
    |> Event.changeset(update_attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_event} ->
        # Invalidar cache si campos relevantes cambiaron
        if cache_invalidation_required?(old_fields, updated_event) do
          EventApi.Summaries.Cache.invalidate(updated_event)
        end

        # Notificar cambios de estado
        notify_status_change(event, updated_event)

        {:ok, updated_event}
      error -> error
    end
  end

  defp cache_invalidation_required?(old_fields, updated_event) do
    old_fields.title != updated_event.title ||
    old_fields.location != updated_event.location ||
    old_fields.start_at != updated_event.start_at ||
    old_fields.end_at != updated_event.end_at
  end

  defp notify_status_change(old_event, new_event) do
    case {old_event.status, new_event.status} do
      {"DRAFT", "PUBLISHED"} ->
        Notifications.notify_event_published(new_event)
      {_, "CANCELLED"} when old_event.status != "CANCELLED" ->
        Notifications.notify_event_cancelled(new_event)
      _ ->
        Notifications.notify_event_updated(new_event)
    end
  end

  @doc """
  List public events (only PUBLISHED and CANCELLED status)
  """
  def list_public_events(params \\ %{}) do
    _public_params = Map.drop(params, ["status"])

    %{events: events, pagination: pagination} =
      params
      |> Map.put("status", "PUBLISHED,CANCELLED")
      |> list_events()

    public_events = Enum.map(events, &Event.public_fields/1)

    %{
      events: public_events,
      pagination: pagination
    }
  end
end
