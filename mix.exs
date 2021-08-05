defmodule ExqlMigration.MixProject do
  use Mix.Project

  def project do
    [
      app: :exql_migration,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer()
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "deps/dialyzer.plt"},
      plt_add_apps: [:postgrex, :db_connection]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:postgrex, ">= 0.0.0", optional: true},
      {:credo, "~> 1.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.github": :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end
end
