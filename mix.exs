defmodule Fiat.MixProject do
  use Mix.Project

  def project do
    [
      app: :fiat,
      version: "1.0.0",
      elixir: "~> 1.13",
      description: description(),
      package: package(),
      source_url: repo_url(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "A simple cache server that leverages ets to hold cached objects."
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:ex_doc, "~> 0.24", only: :dev, runtime: false}, {:benchee, "~> 1.0", only: :dev}]
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => repo_url()}
    ]
  end

  defp repo_url do
    "https://github.com/kinson/fiat"
  end
end
