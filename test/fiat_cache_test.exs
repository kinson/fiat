defmodule FiatCacheTest do
  use ExUnit.Case
  doctest FiatCache.Server

  alias FiatCache.Server

  setup do
    Server.start_link()
    :ok
  end

  test "caches an item" do
    assert Server.cache_object("dog", {"Henry", 4}) == true
    assert Server.fetch_object("dog") == {"Henry", 4}
  end

  test "queries item if object is not in fetch" do
    assert Server.fetch_object("dog", fn () -> {"Henry", 5} end) == {"Henry", 5}
    assert Server.fetch_object("dog") == {"Henry", 5}
    assert Server.fetch_object("dogg") == nil
  end
end
