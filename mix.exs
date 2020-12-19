defmodule DistLimiter.MixProject do
  use Mix.Project

  def project do
    [
      app: :dist_limiter,
      version: "0.1.1",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Distributed Rate Limiter",
      source_url: "https://github.com/jechol/dist_limiter",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DistLimiter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uni_pg, "~> 0.2.1"},
      {:gen_state_machine, "~> 3.0"},
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jechol/dist_limiter"},
      maintainers: ["Jechol Lee(mr.jechol@gmail.com)"]
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "dist_limiter",
      canonical: "http://hexdocs.pm/dist_limiter",
      source_url: "https://github.com/jechol/dist_limiter",
      extras: [
        "README.md"
      ]
    ]
  end
end
