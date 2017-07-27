defmodule NervesSystemTest.Mixfile do
  use Mix.Project

  def project do
    [app: :nerves_system_test,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application() do
    [mod: {NervesSystemTest.Application, []},
     extra_applications: [:logger, :websocket_client, :ssl, :inets,
      :mix, :ex_unit
    ]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  def deps do
    [
      {:bootloader, "~> 0.1"},
      {:nerves_runtime, "~> 0.4"},
      {:nerves_network, "~> 0.1"},
      {:phoenix_gen_socket_client, "~> 1.1.1"},
      {:websocket_client, github: "sanmiguel/websocket_client", tag: "1.2.4"},
      {:poison, "~> 2.1"}
    ]
  end
end
