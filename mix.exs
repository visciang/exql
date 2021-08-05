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
      description: description(),
      package: package(),
      dialyzer: [
        plt_file: {:no_warn, "deps/dialyzer.plt"}
      ]
    ]
  end

  defp description do
    "Simple DB SQL migration script runner (no ecto_sql)."
  end

  defp package do
    [
      name: "dataspecs",
      licenses: ["MIT"],
      files: ["lib", "README.md", "LICENSE", "mix.exs"],
      maintainers: ["Giovanni Visciano"],
      links: %{"GitHub" => "https://github.com/visciang/exql_migration"}
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
