defmodule FiatCache do
  @moduledoc """
  Documentation for `FiatCache`.
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

  def stop do
    GenServer.stop(__MODULE__)
  end

  def cache_object(cache_key, object, expires_in \\ 300) do
    expires_at = System.os_time(:second) + expires_in
    GenServer.call(__MODULE__, {:set, cache_key, object, expires_at})
  end

  def fetch_object(cache_key) do
    GenServer.call(__MODULE__, {:get, cache_key})
  end

  def fetch_object(cache_key, query_fn, expires_in \\ 300) do
    case GenServer.call(__MODULE__, {:get, cache_key}) do
      nil ->
        object = query_fn.()
        cache_object(cache_key, object, expires_in)
        object

      object ->
        object
    end
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

  def handle_call({:get, key}, _from, state) do
    result =
      case :ets.lookup(@table, key) do
        [] -> nil
        [{_, result}] -> result
      end

    {:reply, result, state}
  end

  @impl true
  def handle_info(:clear_stale_objects, state) do
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

    schedule_clear()

    {:noreply, Enum.into(keep, Map.new())}
  end

  defp schedule_clear() do
    Process.send_after(self(), :clear_stale_objects, @clear_interval)
  end

  @impl true
  def terminate(_, _) do
    :ets.delete_all_objects(@table)
  end
end