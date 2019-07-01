defmodule ExMetrics.MixProject do
  use Mix.Project

  @github_url "https://github.com/mpiercy827/ex_metrics"

  def project do
    [
      app: :ex_metrics,
      name: "metrics",
      description: "Another Elixir metrics library.",
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @github_url,
      homepage_url: @github_url,
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.travis": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:mimic, "~> 0.3", only: :test},
      {:plug, "~> 1.8"},
      {:statix, "~> 1.1.0"}
    ]
  end

  defp package do
    [
      files: ~w(mix.exs lib LICENSE* README.md CHANGELOG.md),
      maintainers: ["Matt Piercy"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github_url
      }
    ]
  end
end
