defmodule IotsimWeb.IotSimLive.Index do
  use IotsimWeb, :live_view

  alias Iotsim.Device

  @impl true
  def mount(_params, _session, socket) do
    Device.subscribe_to_all_devices()

    devices =
      Device.get_all_device_states()
      |> IO.inspect()
      |> Enum.into(%{})

    {:ok,
     socket
     |> assign(:devices, devices)
     |> assign(:form, Phoenix.Component.to_form(%{amount: 0}))}
  end

  ## Handle info

  @impl true
  def handle_event("create", %{"amount" => amount}, socket) do
    amount
    |> String.to_integer()
    |> Device.start_devices()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:device_state_changed, device_id, device_state}, socket) do
    devices = socket.assigns.devices |> Map.put(device_id, device_state)

    {:noreply,
     socket
     |> assign(:devices, devices)}
  end
end
