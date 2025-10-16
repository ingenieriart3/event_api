# defmodule EventApi.Summaries.Cache do
#   @moduledoc """
#   In-memory cache for AI-generated summaries using ETS.
#   """
#   use GenServer
#   require Logger

#   # Alias para el proceso GenServer
# #  @name __MODULE__

#   @table_name :summary_cache

#   # Client API
#   def start_link(_opts) do
#     GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
#   end

#   @doc """
#   Get cached summary for an event.
#   """
#   def get(event) do
#     key = generate_key(event)

#     case :ets.lookup(@table_name, key) do
#       [{^key, summary}] ->
#         Logger.info("[SUMMARY_CACHE] HIT for event: #{event.id}")
#         {:ok, summary, key}
#       [] ->
#         Logger.info("[SUMMARY_CACHE] MISS for event: #{event.id}")
#         {:miss, key}
#     end
#   end

#   @doc """
#   Store summary in cache.
#   """
#   def put(event, summary) do
#     key = generate_key(event)
#     GenServer.call(__MODULE__, {:put, key, summary})
#   end

#   @doc """
#   Invalidate cache for an event.
#   """
#   def invalidate(event) do
#     key = generate_key(event)
#     GenServer.call(__MODULE__, {:invalidate, key})
#   end

#   @doc """
#   Generate cache key based on public fields.
#   """
#   def generate_key(event) do
#     public_data = EventApi.Events.Event.public_fields(event)
#     :crypto.hash(:sha256, Jason.encode!(public_data)) |> Base.encode16()
#   end

#   # Server Callbacks
#   @impl true
#   def init(_state) do
#     :ets.new(@table_name, [:named_table, :set, :protected, :compressed])
#     {:ok, %{}}
#   end

#   @impl true
#   def handle_call({:put, key, summary}, _from, state) do
#     :ets.insert(@table_name, {key, summary})
#     {:reply, :ok, state}
#   end

#   @impl true
#   def handle_call({:invalidate, key}, _from, state) do
#     :ets.delete(@table_name, key)
#     Logger.info("[SUMMARY_CACHE] Invalidated key: #{key}")
#     {:reply, :ok, state}
#   end
# end

defmodule EventApi.Summaries.Cache do
  @moduledoc """
  In-memory cache for AI-generated summaries using ETS.
  """
  use GenServer
  require Logger

  @table_name :summary_cache

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Get cached summary for an event.
  Returns {:ok, summary, key} for hits, {:miss, key} for misses.
  """
  def get(event) do
    key = generate_key(event)

    case :ets.lookup(@table_name, key) do
      [{^key, summary}] ->
        Logger.info("[SUMMARY_CACHE] HIT for event: #{event.id}")
        {:ok, summary, key}
      [] ->
        Logger.info("[SUMMARY_CACHE] MISS for event: #{event.id}")
        {:miss, key}
    end
  end

  @doc """
  Store summary in cache.
  """
  def put(event, summary) do
    key = generate_key(event)
    GenServer.call(__MODULE__, {:put, key, summary})
  end

  @doc """
  Invalidate cache for an event.
  """
  def invalidate(event) do
    key = generate_key(event)
    GenServer.call(__MODULE__, {:invalidate, key})
  end

  @doc """
  Generate cache key based on public fields.
  """
  def generate_key(event) do
    public_data = EventApi.Events.Event.public_fields(event)
    :crypto.hash(:sha256, Jason.encode!(public_data)) |> Base.encode16()
  end

  # Server Callbacks
  @impl true
  def init(_state) do
    :ets.new(@table_name, [:named_table, :set, :protected, :compressed])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:put, key, summary}, _from, state) do
    :ets.insert(@table_name, {key, summary})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:invalidate, key}, _from, state) do
    :ets.delete(@table_name, key)
    Logger.info("[SUMMARY_CACHE] Invalidated key: #{key}")
    {:reply, :ok, state}
  end
end
