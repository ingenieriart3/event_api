# # defmodule EventApi.Events do
# #   @moduledoc """
# #   The Events context.
# #   """

# #   import Ecto.Query, warn: false
# #   alias EventApi.Repo

# #   alias EventApi.Events.Event

# #   @doc """
# #   Returns the list of events.

# #   ## Examples

# #       iex> list_events()
# #       [%Event{}, ...]

# #   """
# #   def list_events do
# #     Repo.all(Event)
# #   end

# #   @doc """
# #   Gets a single event.

# #   Raises `Ecto.NoResultsError` if the Event does not exist.

# #   ## Examples

# #       iex> get_event!(123)
# #       %Event{}

# #       iex> get_event!(456)
# #       ** (Ecto.NoResultsError)

# #   """
# #   def get_event!(id), do: Repo.get!(Event, id)

# #   @doc """
# #   Creates a event.

# #   ## Examples

# #       iex> create_event(%{field: value})
# #       {:ok, %Event{}}

# #       iex> create_event(%{field: bad_value})
# #       {:error, %Ecto.Changeset{}}

# #   """
# #   def create_event(attrs) do
# #     %Event{}
# #     |> Event.changeset(attrs)
# #     |> Repo.insert()
# #   end

# #   @doc """
# #   Updates a event.

# #   ## Examples

# #       iex> update_event(event, %{field: new_value})
# #       {:ok, %Event{}}

# #       iex> update_event(event, %{field: bad_value})
# #       {:error, %Ecto.Changeset{}}

# #   """
# #   def update_event(%Event{} = event, attrs) do
# #     event
# #     |> Event.changeset(attrs)
# #     |> Repo.update()
# #   end

# #   @doc """
# #   Deletes a event.

# #   ## Examples

# #       iex> delete_event(event)
# #       {:ok, %Event{}}

# #       iex> delete_event(event)
# #       {:error, %Ecto.Changeset{}}

# #   """
# #   def delete_event(%Event{} = event) do
# #     Repo.delete(event)
# #   end

# #   @doc """
# #   Returns an `%Ecto.Changeset{}` for tracking event changes.

# #   ## Examples

# #       iex> change_event(event)
# #       %Ecto.Changeset{data: %Event{}}

# #   """
# #   def change_event(%Event{} = event, attrs \\ %{}) do
# #     Event.changeset(event, attrs)
# #   end
# # end


# defmodule EventApi.Events do
#   import Ecto.Query, warn: false
#   alias EventApi.Repo
#   alias EventApi.Events.Event
#   alias EventApi.Events.Notifications

#   @doc """
#   Returns the list of events with filtering by date range and locations.
#   """
#   def list_events(params \\ %{}) do
#     Event
#     |> apply_filters(params)
#     |> Repo.all()
#   end

#   defp apply_filters(query, %{"start_date" => start_date, "end_date" => end_date, "locations" => locations}) do
#     start_datetime = parse_datetime(start_date)
#     end_datetime = parse_datetime(end_date)
#     location_list = String.split(locations, ",")

#     query
#     |> where([e], e.start_date >= ^start_datetime and e.end_date <= ^end_datetime)
#     |> where([e], e.location in ^location_list)
#     |> order_by([e], asc: e.start_date)
#   end

#   defp apply_filters(query, %{"start_date" => start_date, "end_date" => end_date}) do
#     start_datetime = parse_datetime(start_date)
#     end_datetime = parse_datetime(end_date)

#     query
#     |> where([e], e.start_date >= ^start_datetime and e.end_date <= ^end_datetime)
#     |> order_by([e], asc: e.start_date)
#   end

#   defp apply_filters(query, %{"locations" => locations}) do
#     location_list = String.split(locations, ",")

#     query
#     |> where([e], e.location in ^location_list)
#     |> order_by([e], asc: e.start_date)
#   end

#   defp apply_filters(query, _params), do: query

#   @doc """
#   Gets a single event.
#   """
#   def get_event!(id), do: Repo.get!(Event, id)

#   @doc """
#   Creates a event.
#   """
#   def create_event(attrs \\ %{}) do
#     %Event{}
#     |> Event.changeset(attrs)
#     |> Repo.insert()
#     |> case do
#       {:ok, event} ->
#         Notifications.notify_event_created(event)
#         {:ok, event}
#       error -> error
#     end
#   end

#   @doc """
#   Updates a event.
#   """
#   def update_event(%Event{} = event, attrs) do
#     old_fields = %{
#       title: event.title,
#       location: event.location,
#       start_date: event.start_date,
#       end_date: event.end_date
#     }

#     event
#     |> Event.changeset(attrs)
#     |> Repo.update()
#     |> case do
#       {:ok, updated_event} ->
#         # Invalidar cache si campos relevantes cambiaron
#         if cache_invalidation_required?(old_fields, updated_event) do
#           EventApi.Summaries.Cache.invalidate(updated_event)
#         end

#         # Notificar cambios de estado
#         if attrs["status"] && attrs["status"] != event.status do
#           Notifications.notify_status_change(updated_event, event.status)
#         else
#           Notifications.notify_event_updated(updated_event)
#         end

#         {:ok, updated_event}
#       error -> error
#     end
#   end

#   defp cache_invalidation_required?(old_fields, updated_event) do
#     old_fields.title != updated_event.title ||
#     old_fields.location != updated_event.location ||
#     old_fields.start_date != updated_event.start_date ||
#     old_fields.end_date != updated_event.end_date
#   end

#   defp parse_datetime(datetime_string) when is_binary(datetime_string) do
#     case DateTime.from_iso8601(datetime_string) do
#       {:ok, datetime, _} -> datetime
#       _ -> nil
#     end
#   end
#   defp parse_datetime(%DateTime{} = datetime), do: datetime
#   defp parse_datetime(_), do: nil
# end

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
    start_date = Date.from_iso8601!(date_from) |> DateTime.beginning_of_day()
    end_date = Date.from_iso8601!(date_to) |> DateTime.end_of_day()

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
    public_params = Map.drop(params, ["status"])

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
