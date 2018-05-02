defmodule Mix.Tasks.Json.Encode do

  @moduledoc """
  JSON Encode all flags out to a file
  Example
    $ mix json.encode context.json --repo-name nerves-project --enabled
    $ cat context.json
    {"--repo-name":"nerves-project","enabled":true}
  """

  def run([file | argv]) do
    {opts2, _, opts} = OptionParser.parse(argv) |> IO.inspect
    opts = Enum.map(opts, &strip/1)
    opts = (opts ++ opts2) |> Enum.into(%{})

    file = Path.expand(file)
    with {:ok, json} <- Jason.encode(opts),
                 :ok <- File.write(file, json) do
      :ok
    else
      {:error, error} -> Mix.raise("Error writing json to file #{file} #{error}")
    end
  end

  def strip({k, v}) do
    k = k
      |> String.trim_leading("--")
      |> String.replace("-", "_")
    {k, v}
  end
end
