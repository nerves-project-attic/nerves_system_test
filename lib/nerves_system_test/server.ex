defmodule Nerves.System.Test.Server do
  use GenServer

  require Logger

  alias Mix.Compilers.Test, as: CT

  @target Mix.Project.config[:target]
  @scope [:state, :network_interface]
  @iface "wlan0"

  alias Nerves.System.Test.{Channel, Socket, HTTPClient}

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    :os.cmd 'epmd -daemon'
    SystemRegistry.register
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)
    {:ok, %{
      channel: nil,
      socket: nil,
      hostname: hostname,
      iface: @iface,
      ip: nil,
      test_io: nil,
      test_results: nil
    }}
  end

  def handle_info({:system_registry, :global, registry}, %{iface: iface, ip: current} = s) do
    scope = scope(iface, [:ipv4_address])
    ip = get_in(registry, scope)
    s =
    if ip != current do
      Logger.debug "IP Address Changed"
      Logger.debug "IP: #{inspect ip} Current: #{inspect current}"
      ntpd()
      connect(s)
    else
      s
    end

    {:noreply, %{s | ip: ip}}
  end

  def handle_info({:test_result, result}, s) do
    Logger.debug "Received Results: #{inspect result}"
    {:noreply, %{s | test_results: result}}
  end

  defp ntpd do
    Logger.debug "Updating System Time"
    System.cmd("ntpd", ["-q", "-p", "pool.ntp.org"])
  end

  defp scope(iface, append) do
    @scope ++ [iface] ++ append
  end

  def connect(s) do
    Logger.debug "Connecting to server"
    with {:ok, _socket} <- Socket.start_link,
         {:ok, _channel} <- PhoenixChannelClient.channel(Channel, socket: Socket, topic: "device:#{s.hostname}") do

        Logger.debug "Join Channel"
        Channel.join(%{target: @target})
        # {:ok, http} = HTTPClient.start_link()
        # HTTPClient.get(http, "http://192.168.1.139:4000/firmware")
        %{s | test_io: run_tests()}
    else
      error ->
        Logger.debug "Failed to connect: #{inspect error}"
        s
    end
  end

  def run_tests do
    priv_dir =
      :code.priv_dir(:nerves_system_test) |> to_string
    test_dir = Path.join([priv_dir, "test"])
    test_files = Path.join([test_dir, "nerves_system_test_test.exs"])
    Code.require_file Path.join([test_dir, "test_helper.exs"])
    pid = self()
    fun =
      fn() ->
        result = CT.require_and_run([test_files], [test_files], test_dir, [autorun: false])
        send(pid, {:test_result, result})
      end
    ExUnit.CaptureIO.capture_io(fun)

  end
end
