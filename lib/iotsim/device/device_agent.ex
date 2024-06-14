defmodule Iotsim.Device.DeviceAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def get_device_ids() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def add_device_id(device_id) do
    Agent.update(__MODULE__, fn state -> [device_id | state] end)
  end
end
