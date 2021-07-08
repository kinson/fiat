defmodule Fiat.CacheServer do
  @moduledoc """
  Fiat is a module to handle basic caching needs. Behind
  the scenes it leverages an ets table to store objects
  and a GenServer to maintain the state of the current
  keys.

  ## Usage

  Add `Fiat.CacheServer` to your application's supervision
  tree. Because `Fiat.CacheServer` is registered with its
  module name, it can be accessed without providing a pid
  to access the process.

  For example:

  ```elixir
  children = [
    ...
    Fiat.CacheServer
  ]
  ...
  ```
  """

  use GenServer

  @table :table
  @clear_interval :timer.seconds(5)

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_link() do
    start_link([])
  end

  @doc """
  Stops the GenServer.

  ## Examples

    iex> Fiat.CacheServer.stop()
    :ok

  """
  @spec stop() :: :ok
  def stop do
    GenServer.stop(__MODULE__)
  end

  @doc """
  Caches an object using a cache_key.

  ## Examples

    iex> Fiat.CacheServer.cache_object("data", {"code", 2})
    true

    iex> Fiat.CacheServer.cache_object("data", {"code", 2}, 10)
    true

  """
  @spec cache_object(term(), term(), integer()) :: true
  def cache_object(cache_key, object, expires_in \\ 300) do
    expires_at = System.os_time(:second) + expires_in
    GenServer.call(__MODULE__, {:set, cache_key, object, expires_at})
  end

  @doc """
  Fetches the cached object for a particular key.

  Returns object if it exists in the cache, otherwise
  returns `nil`.

  ## Examples

    iex> Fiat.CacheServer.cache_object("data", {"code", 2})
    iex> Fiat.CacheServer.fetch_object("data")
    {"code", 2}

    iex> Fiat.CacheServer.fetch_object("data_old")
    nil

  """
  @spec fetch_object(term()) :: term() | nil
  def fetch_object(cache_key) do
    case :ets.lookup(@table, cache_key) do
      [] -> nil
      [{_, result}] -> result
    end
  end

  @doc """
  Fetches the cached object for a particular key. If
  the `cache_key` is not present in the cache, it
  executes the provided `query_fn` paramter, stores
  the result in the cache and returns it.

  Returns either the cached object or the result of
  the `query_fn` parameter.

  ## Examples

    iex> Fiat.CacheServer.cache_object("data", :data)
    iex> Fiat.CacheServer.fetch_object("data", fn -> :ok end)
    :data

    iex> Fiat.CacheServer.fetch_object("data", fn -> :ok end)
    :ok

  """
  @spec fetch_object(term(), (() -> term()), integer()) :: term()
  def fetch_object(cache_key, query_fn, expires_in \\ 300) do
    case fetch_object(cache_key) do
      nil ->
        object = query_fn.()
        cache_object(cache_key, object, expires_in)
        object

      object ->
        object
    end
  end

  @doc """
  Clears stale items from the cache.

  ## Examples

    iex> Fiat.CacheServer.clear_stale_objects
    []

  """
  def clear_stale_objects() do
    GenServer.call(__MODULE__, :clear_stale_objects)
  end

  @impl true
  def init(_) do
    :ets.new(@table, [
      :set,
      :named_table,
      read_concurrency: true
    ])

    schedule_clear()

    {:ok, %{}}
  end

  @impl true
  def handle_call({:set, key, object, expires_at}, _from, state) do
    result = :ets.insert(@table, {key, object})

    {:reply, result, Map.put(state, key, expires_at)}
  end

  def handle_call(:clear_stale_objects, _from, state) do
    new_state = remove_stale_objects(state)

    {:reply, [], new_state}
  end

  @impl true
  def handle_info(:clear_stale_objects, state) do
    new_state = remove_stale_objects(state)

    schedule_clear()

    {:noreply, new_state}
  end

  @impl true
  def terminate(_, _) do
    :ets.delete_all_objects(@table)
  end

  defp remove_stale_objects(state) do
    now = System.os_time(:second)

    {keys_to_delete, keep} =
      Map.to_list(state)
      |> Enum.reduce({[], []}, fn {key, expires_at}, {to_delete, to_keep} ->
        if now > expires_at do
          {to_delete ++ [key], to_keep}
        else
          {to_delete, to_keep ++ [{key, expires_at}]}
        end
      end)

    Enum.each(keys_to_delete, &:ets.delete(@table, &1))

    Enum.into(keep, Map.new())
  end

  defp schedule_clear() do
    Process.send_after(self(), :clear_stale_objects, @clear_interval)
  end
end
