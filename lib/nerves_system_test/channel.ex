defmodule Nerves.System.Test.Channel do
  use PhoenixChannelClient

  require Logger

  def handle_in("new_msg", _payload, state) do
    {:noreply, state}
  end

  def handle_reply({:ok, :join, resp, _ref}, state) do
    Logger.debug "Joined: #{inspect resp}"
    
    {:noreply, state}
  end

  def handle_reply({:ok, "new_msg", _resp, _ref}, state) do
    {:noreply, state}
  end
  def handle_reply({:error, "new_msg", _resp, _ref}, state) do
    {:noreply, state}
  end
  def handle_reply({:timeout, "new_msg", _ref}, state) do
    {:noreply, state}
  end

  def handle_reply({:timeout, :join, _ref}, state) do
    {:noreply, state}
  end

  def handle_close(reason, _state) do
    {:stop, reason}
  end
end
