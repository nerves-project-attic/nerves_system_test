defmodule NervesSystemTest.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nerves_system_test,
      version: "0.1.0",
      elixir: "~> 1.8",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application() do
    [
      mod: {NervesSystemTest.Application, []},
      extra_applications: [
        :logger,
        :websocket_client,
        :ssl,
        :inets,
        :mix,
        :ex_unit
      ]
    ]
  end

  def deps do
    [
      {:shoehorn, "~> 0.2"},
      {:nerves_runtime, "~> 0.6"},
      {:nerves_network, "~> 0.1"},
      {:nerves_watchdog, github: "mobileoverlord/nerves_watchdog"},
      {:nerves_hub, github: "nerves-hub/nerves_hub"},
      {:phoenix_client, "~> 0.7"},
      {:jason, "~> 1.0"},
      {:system_registry_term_storage, "~> 0.1"}
    ]
  end
end
