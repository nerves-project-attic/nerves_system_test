defmodule NervesRuntime.Test do
  use ExUnit.Case

  describe "application data partition" do
    # on_exit fn ->
    #   :os.cmd('umount /root')
    # end

    test "can be written to" do
      file = "/root/tmp"
      content = "hello"
      assert :ok == File.write(file, content)
      assert {:ok, content} == File.read(file)
    end
  end

  describe "key value store" do
    test "can be read from" do
      tests = Application.get_env(:nerves_system_test, :kv)
      assert Enum.all?(tests, fn({k, v}) ->
        v =
          to_string(v)
          |> String.trim()
        kv =
          to_string(k)
          |> Nerves.Runtime.KV.get_active()
          |> String.trim()
        IO.inspect k
        #IO.inspect kv
        v == kv
      end)

    end
  end

end
