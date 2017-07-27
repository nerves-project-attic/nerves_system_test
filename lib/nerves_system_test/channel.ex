defmodule NervesSystemTest.Channel do
  #use GenServer
  #use PhoenixChannelClient
  alias Phoenix.Channels.GenSocketClient
  alias Mix.Compilers.Test, as: CT
  alias NervesSystemTest.HTTPClient
  @behaviour GenSocketClient
  require Logger

  def start_link(opts) do
    url = opts[:url] || "ws://localhost:4000/socket/websocket"
    GenSocketClient.start_link(
      __MODULE__,
      Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
      url
    )
  end

  def init(url) do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)
    system = Application.get_env(:nerves_system_test, :system)
    send(self(), :test_begin)
    {:connect, url, %{
      topic: "device:#{hostname}",
      hostname: hostname,
      system: system,
      status: :testing,
      vcs_id: Nerves.Runtime.KV.get_active(:nerves_fw_vcs_identifier),
      vcs_branch: Nerves.Runtime.KV.get_active(:nerves_fw_misc),
      test_io: nil,
      test_results: nil,
      http: nil
    }}
  end

  def handle_connected(transport, s) do
    Logger.info("connected")
    payload = Map.take(s, [:system, :status])
    GenSocketClient.join(transport, s.topic, payload)
    {:ok, s}
  end

  def handle_disconnected(reason, s) do
    Logger.error("disconnected: #{inspect reason}")
    Process.send_after(self(), :connect, :timer.seconds(1))
    {:ok, s}
  end

  def handle_joined(topic, _payload, transport, s) do
    Logger.info("joined the topic #{topic}")
    deliver_results(transport, s)
    {:ok, s}
  end

  def handle_join_error(topic, payload, _transport, s) do
    Logger.error("join error on the topic #{topic}: #{inspect payload}")
    {:ok, s}
  end

  def handle_channel_closed(topic, payload, _transport, s) do
    Logger.error("disconnected from the topic #{topic}: #{inspect payload}")
    Process.send_after(self(), {:join, topic}, :timer.seconds(1))
    {:ok, s}
  end

  def handle_message(_topic, "apply", %{"fw" => fw_file}, _transport, s) do
    Logger.debug("Download firmware: #{fw_file}")
    {:ok, http} = HTTPClient.start_link(self())
    HTTPClient.get(http, fw_file)
    {:ok, %{s | http: http}}
  end

  def handle_message(topic, event, payload, _transport, s) do
    Logger.warn("message on topic #{topic}: #{event} #{inspect payload}")
    {:ok, s}
  end

  def handle_reply(_topic, _ref, %{"response" => %{"test" => "ok"}, "status" => "ok"}, _transport, s) do
    Logger.debug("Test results received")
    {:ok, %{s | status: :ready}}
  end

  def handle_reply(_topic, _ref, %{"response" => %{"test" => "begin"}, "status" => "ok"}, _transport, s) do
    Logger.debug("Test Begin")
    Application.stop :system_registry
    Nerves.Runtime.reboot()
    {:ok, s}
  end

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.warn("reply on topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_info(:connect, _transport, s) do
    Logger.info("connecting")
    {:connect, s}
  end

  def handle_info({:fwup, :done}, transport, s) do
    Logger.debug "FWUP Finished"
    GenSocketClient.push(transport, s.topic, "test_begin", %{})
    {:ok, %{s | status: :rebooting}}
  end

  def handle_info(:test_begin, _transport, s) do
    Logger.debug "Starting Tests"
    {:ok, %{s | test_io: run_tests(), status: :testing}}
  end

  def handle_info({:test_result, {:ok, result}}, transport, s) do
    s = %{s | test_results: result, status: :ready}

    deliver_results(transport, s)
    Logger.debug "Received Results: #{inspect result}"
    {:ok, %{s | status: :deliver}}
  end

  def handle_info(message, _transport, s) do
    Logger.warn("Unhandled message #{inspect message}")
    {:ok, s}
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

  defp deliver_results(transport, %{status: :deliver} = s) do
    payload = Map.take(s, [:test_results, :test_io, :status])
    GenSocketClient.push(transport, s.topic, "test_results", payload)
  end
  defp deliver_results(_, _), do: :noop
end
