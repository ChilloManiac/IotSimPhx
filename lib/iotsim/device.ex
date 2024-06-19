defmodule Iotsim.Device do
  require Logger

  import Phoenix.PubSub

  def start_devices(amount \\ 1) do
    for _ <- 1..amount do
      uuid = UUID.uuid4()
      child_spec = {Iotsim.Device.DeviceSim, uuid}
      DynamicSupervisor.start_child(Iotsim.DynamicSupervisor, child_spec)
      Iotsim.Device.DeviceAgent.add_device_id(uuid)
      uuid
    end
  end

  def get_devices() do
    Iotsim.Device.DeviceAgent.get_device_ids()
  end

  def get_device_state(device_id) do
    device_id
    |> Iotsim.Device.DeviceSim.get_state(:detailed)
  end

  def get_all_device_states() do
    get_devices()
    |> Enum.map(&Iotsim.Device.DeviceSim.get_state/1)
  end

  def set_device_state(device_id, state) do
    Iotsim.Device.DeviceSim.set_state(device_id, state)
  end

  def reset_device_failures(device_id) do
    Iotsim.Device.DeviceSim.reset_failures(device_id)
  end

  def subscribe_to_all_devices() do
    subscribe(Iotsim.PubSub, "device_state/all")
  end

  def subscribe_to_detailed_devices(device_id) do
    subscribe(Iotsim.PubSub, "device_state/detailed/#{device_id}")
  end
end
