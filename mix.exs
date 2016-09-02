defmodule GithubCi.Mixfile do
  use Mix.Project

  def project do
    [app: :github_ci,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {GithubCi, []},
     applications: [:phoenix, :cowboy, :logger, :gettext, :tentacat, :httpoison]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.1"},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0.4"},
     {:tentacat, "~> 0.5"},
     {:poison, "~> 2.0"},
     {:httpoison, "~> 0.9.0"}
   ]
  end
end
