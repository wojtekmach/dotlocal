defmodule DotLocal.MixProject do
  use Mix.Project

  def project do
    [
      app: :dotlocal,
      version: "0.1.0",
      elixir: "~> 1.6-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:cowboy, "~> 1.0", only: :test},
      {:plug, "~> 1.0", only: :test},
      {:httpoison, "~> 1.0", only: :test}
    ]
  end
end
