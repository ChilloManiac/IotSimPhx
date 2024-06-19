defmodule IotsimWeb.IotSimLive.Show do
  use IotsimWeb, :live_view

  alias Iotsim.Device

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    Device.subscribe_to_detailed_devices(id)

    {:noreply,
     socket
     |> assign(:device, Device.get_device_state(id))}
  end

  @impl true
  def handle_info({:detailed_state, state}, socket) do
    IO.inspect(state)
    {:noreply, assign(socket, :device, state)}
  end

  @impl true
  def handle_event("set_state", %{"action" => action}, socket) do
    action =
      case action do
        "starting" -> :starting
        "running" -> :running
        "error" -> :error
        "broken" -> :broken
      end

    Device.set_device_state(socket.assigns.device.id, action)

    {:noreply, socket}
  end

  @impl true
  def handle_event("reset_failures", _, socket) do
    Device.reset_device_failures(socket.assigns.device.id)

    {:noreply, socket}
  end
end
