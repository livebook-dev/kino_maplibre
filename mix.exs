defmodule KinoMapLibre.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "MapLibre integration with Livebook"

  def project do
    [
      app: :kino_maplibre,
      version: @version,
      description: @description,
      name: "KinoMapLibre",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {KinoMapLibre.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kino, "~> 0.6.1"},
      {:table, "~> 0.1.0"},
      {:maplibre, github: "livebook-dev/maplibre"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "components",
      source_url: "https://github.com/livebook-dev/kino_maplibre",
      source_ref: "v#{@version}",
      extras: ["guides/components.livemd"],
      groups_for_modules: [
        Kinos: [
          Kino.MapLibre
        ]
      ]
    ]
  end
end
