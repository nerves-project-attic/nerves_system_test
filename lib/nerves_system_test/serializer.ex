defmodule NervesSystemTest.JasonSerializer do
  @moduledoc "Jason serializer for the socket client."
  @behaviour Phoenix.Channels.GenSocketClient.Serializer

  # -------------------------------------------------------------------
  # Phoenix.Channels.GenSocketClient.Serializer callbacks
  # -------------------------------------------------------------------

  @doc false
  def decode_message(encoded_message), do: Jason.decode!(encoded_message)

  @doc false
  def encode_message(message) do
    case Jason.encode(message) do
      {:ok, encoded} -> {:ok, {:binary, encoded}}
      error -> error
    end
  end
end
