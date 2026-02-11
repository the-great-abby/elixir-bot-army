defmodule BotArmy.MixProject do
  use Mix.Project

  def project do
    [
      app: :bot_army,
      version: "0.1.0",
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
    [
      extra_applications: [:logger],
      mod: {BotArmy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gnat, "~> 1.8"},
      {:jason, "~> 1.4"},
      {:postgrex, "~> 0.17"}
    ]
  end
end
