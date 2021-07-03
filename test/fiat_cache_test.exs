defmodule FiatCacheTest do
  use ExUnit.Case
  doctest FiatCache

  test "caches an item" do
    FiatCache.start_link()

    assert FiatCache.cache_object("dog", {"Henry", 4}) == true
    assert FiatCache.fetch_object("dog") == {"Henry", 4}

    FiatCache.stop()
  end

  test "queries item if object is not in fetch" do
    FiatCache.start_link()

    assert FiatCache.fetch_object("dog", fn () -> {"Henry", 5} end) == {"Henry", 5}
    assert FiatCache.fetch_object("dog") == {"Henry", 5}
    assert FiatCache.fetch_object("dogg") == nil

    FiatCache.stop()
  end
end
