Fiat.CacheServer.start_link()

sample_data = %{
  data: "a long string that represents a lot of data.
    a long string that represents a lot of data.
    a long string that represents a lot of data.
    a long string that represents a lot of data."
}

task = fn ->
  Enum.each(1..1_000, &Fiat.CacheServer.cache_object("item#{&1}", sample_data))
  Enum.each(1..1_000, &Fiat.CacheServer.fetch_object("item#{&1}"))
  Enum.each(1..500, &Fiat.CacheServer.cache_object("item#{&1}", sample_data))
  Enum.each(1..10_000, &Fiat.CacheServer.fetch_object("item#{&1}"))
  Enum.each(1..500, &Fiat.CacheServer.cache_object("item#{&1}", sample_data))
  Enum.each(1..10_000, &Fiat.CacheServer.fetch_object("item#{&1}"))
  Enum.each(1..500, &Fiat.CacheServer.cache_object("item#{&1}", sample_data))
  Enum.each(1..10_000, &Fiat.CacheServer.fetch_object("item#{&1}"))
end

Benchee.run(
  %{
    "add_to_cache" => fn -> task.() end
  },
  memory_time: 4,
  parallel: 4
)

Fiat.CacheServer.stop()
