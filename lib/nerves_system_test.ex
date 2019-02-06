defmodule NervesSystemTest do
  use GenServer

  alias Mix.Compilers.Test, as: CT
  alias PhoenixClient.{Socket, Channel, Message}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    socket = opts[:socket]
    serial = opts[:serial]
    fw_metadata = opts[:fw_metadata]

    {:ok, %{
      socket: socket,
      channel: nil,
      result: nil,
      io: nil,
      serial: serial,
      fw_metadata: fw_metadata
    }, {:continue, nil}}
  end

  def handle_continue(nil, s) do
    {:noreply, %{s | io: run_tests()}}
  end

  # Test results received
  def handle_info({:test_result, result}, s) do
    send(self(), :connect)
    {:noreply, %{s | result: result}}
  end

  # Try to connect to the server
  def handle_info(:connect, s) do
    if Socket.connected?(Socket) do
      {:ok, _reply, _channel} = Channel.join(Socket, "device:" <> s.serial, s.fw_metadata)
    else
      Process.send_after(self(), :connect, 1_000)
    end
    {:noreply, s}
  end

  # If the remote socket closes, send a message to reconnect
  def handle_info(%Message{event: event}, s) when event in ["phx_error", "phx_close"] do
    send(self(), :connect)
    {:noreply, s}
  end

  # Private helper functions

  defp run_tests(pid \\ nil) do
    test_paths = test_paths()
    Enum.each(test_paths, &require_test_helper/1)
    test_pattern = "*_test.exs"
    matched_test_files = Mix.Utils.extract_files(test_paths, test_pattern)

    pid = pid || self()
    fun =
      fn() ->
        result = CT.require_and_run(matched_test_files, test_paths, [autorun: false])
        send(pid, {:test_result, result})
      end
    ExUnit.CaptureIO.capture_io(fun)
  end

  defp test_paths() do
    tests = Application.get_env(:nerves_system_test, :tests, []) ++ default_tests()
    Enum.map(tests, &parse_test_path/1)
  end

  defp parse_test_path({app, :priv_dir, path}) do
    :code.priv_dir(app)
    |> to_string
    |> Path.join(path)
  end

  defp parse_test_path({_app, opt, _path}), do:
    raise "#{inspect opt} is not implemented"

  defp default_tests() do
    [{:nerves_system_test, :priv_dir, "test"}]
  end

  defp require_test_helper(dir) do
    file = Path.join(dir, "test_helper.exs")

    if File.exists?(file) do
      Code.require_file file
    else
      Mix.raise "Cannot run tests because test helper file #{inspect file} does not exist"
    end
  end
end
