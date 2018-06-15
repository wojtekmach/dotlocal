defmodule DotLocal.MixProject do
  use Mix.Project

  def project do
    [
      app: :dotlocal,
      version: "0.1.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {DotLocal.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.0"},
      {:cowboy, "~> 1.0"},

      {:httpoison, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
