defmodule App.Mixfile do
  use Mix.Project

  def project do
    [app: :app,
     version: "0.1.0",
     elixir: "~> 1.3",
     default_task: "server",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases()]
  end

  def application do
    [applications: [:logger, :nadia, :httpoison, :calendar, :dogstatsd],
     mod: {App, []}]
  end

  defp deps do
    [{:nadia, "~> 0.4.1"},
     {:feeder_ex, "~> 0.0.5"},
     {:httpoison, "~> 0.10.0"},
     {:stash, "~> 1.0.0"},
     {:calendar, "~> 0.16.1"},
     {:html_entities, "~> 0.3.0"},
     {:dogstatsd, "0.0.3"}]
  end

  defp aliases do
    [server: "run --no-halt"]
  end
end
