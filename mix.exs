defmodule BotArmy.MixProject do
  use Mix.Project

  def project do
    [
      app: :bot_army,
      version: "0.1.2",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  defp releases do
    [
      bot_army: [
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    base = [extra_applications: [:logger]]
    # In test we don't start the app so tests can run without NATS
    if Mix.env() == :test do
      base
    else
      Keyword.put(base, :mod, {BotArmy.Application, []})
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gnat, "~> 1.8"},
      {:jason, "~> 1.4"},
      {:postgrex, "~> 0.17"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
