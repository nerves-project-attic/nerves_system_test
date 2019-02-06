defmodule NervesSystemTest.Application do
  use Application

  alias PhoenixClient.Socket

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    socket_opts =
      Application.get_env(:nerves_system_test, :socket)

    # Define workers and child supervisors to be supervised
    children = [
      {Socket, {socket_opts, name: Socket}},
      {NervesSystemTest, test_opts()}
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesSystemTest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp test_opts() do
    serial = Nerves.Runtime.KV.get("nerves_serial_number")
    fw_metadata = Nerves.Runtime.KV.get_all_active()

    Application.get_all_env(:nerves_system_test)
    |> Keyword.put_new(:socket, Socket)
    |> Keyword.put(:serial, serial)
    |> Keyword.put(:fw_metadata, fw_metadata)
  end
end
