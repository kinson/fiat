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
end
