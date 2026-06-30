defmodule CentrixCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :centrix_core,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
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
      {:ecto_sql, "~> 3.13.2"},
      {:xml_builder, "~> 2.4.0"},
      {:req, "~> 0.6"},
      {:timex, "~> 3.7.13"},
      {:xmerl_c14n, "~> 0.2.0"},
      {:sweet_xml, "~> 0.7.4"},
      {:mimic, "~> 2.0.0", only: :test},
      {:poison, "~> 6.0.0"},
      {:elixir_xml_to_map, "~> 3.1.0"},
      {:pdf, "~> 0.7.1"},
      {:barlix, "~> 0.6"},
      {:decimal, "~> 2.0"},
      {:styler, "~> 1.11", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false, warn_if_outdated: true},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      precommit: [
        "compile --warning-as-errors",
        "deps.unlock --unused",
        "format",
        "credo --strict",
        "sobelow",
        "deps.audit --ignore-advisory-ids GHSA-rhv4-8758-jx7v",
        "test"
      ]
    ]
  end
end
