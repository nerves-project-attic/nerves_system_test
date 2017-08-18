defmodule Mix.Tasks.Json.Encode do

  @moduledoc """
  JSON Encode all flags out to a file
  Example
    mix json.encode /my/file --repo-name nerves-project

  """

  def run([file | argv]) do
    {_, _, opts} = OptionParser.parse(argv)
    json =
      opts
      |> Enum.into(%{})
      |> Poison.encode!
    file = Path.expand(file)
    case File.write(file, json) do
      {:error, error} -> Mix.raise("Error writing json to file #{file} #{error}")
      :ok -> :ok
    end
  end
end
