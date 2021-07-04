defmodule FiatTest do
  use ExUnit.Case
  doctest Fiat.CacheServer

  alias Fiat.CacheServer

  setup do
    CacheServer.start_link()
    :ok
  end

  test "caches an item" do
    assert CacheServer.cache_object("dog", {"Henry", 4}) == true
    assert CacheServer.fetch_object("dog") == {"Henry", 4}
  end

  test "queries item if object is not in fetch" do
    assert CacheServer.fetch_object("dog", fn -> {"Henry", 5} end) == {"Henry", 5}
    assert CacheServer.fetch_object("dog") == {"Henry", 5}
    assert CacheServer.fetch_object("dogg") == nil
  end

  test "returns cached item and does not execute query" do
    CacheServer.cache_object("dog", {"Henry", 4})

    # because the value is already present, the function will not be
    # executed, so in this case the value would not be updated in fiat
    assert CacheServer.fetch_object("dog", fn -> {"Henry", 9} end) == {"Henry", 4}
  end

  test "clears cache when ttl is done" do
    CacheServer.cache_object("dog", {"Henry", 4}, -1)
    CacheServer.cache_object("cat", {"Kali", 4}, 5)
    Process.send(CacheServer, :clear_stale_objects, [])

    :timer.sleep(10)
    assert is_nil(CacheServer.fetch_object("dog"))
    refute is_nil(CacheServer.fetch_object("cat"))
  end

  test "server can be stopped" do
    refute is_nil(Process.whereis(CacheServer))

    CacheServer.stop()

    assert is_nil(Process.whereis(CacheServer))
  end
end
