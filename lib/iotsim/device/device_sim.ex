defmodule Iotsim.Device.DeviceSim do
  use GenServer
  require Logger

  import Phoenix.PubSub

  defstruct id: nil, device_state: :starting, failures: 0, events: []

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  def get_state(id) do
    id
    |> via_tuple()
    |> GenServer.call(:get_state)
  end

  ## GenServer callbacks

  @impl true
  def init(id) do
    Iotsim.Ticker.subscribe()
    {:ok, %__MODULE__{id: id}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:tick, %__MODULE__{device_state: device_state, failures: failures} = state) do
    device_state =
      case device_state do
        :starting ->
          :running

        :running ->
          if :rand.uniform() < 0.1 do
            if failures == 2 do
              :broken
            else
              :error
            end
          else
            :running
          end

        :error ->
          :starting

        :broken ->
          :broken

        _ ->
          raise "Unknown device state: #{device_state}"
      end

    next_state =
      state
      |> Map.put(:device_state, device_state)
      |> assign_changes_if_changed(state.device_state)

    broadcast_if_changed(next_state, state.device_state)

    {:noreply, next_state}
  end

  ## Private functions

  defp via_tuple(id) do
    {:via, Registry, {Iotsim.Registry, id}}
  end

  defp format_event(device_state, device_state_before) do
    "#{DateTime.utc_now()} - Device state changed from #{device_state_before} to #{device_state}"
  end

  defp assign_changes_if_changed(%__MODULE__{device_state: d} = state, d),
    do: state

  defp assign_changes_if_changed(
         %__MODULE__{failures: failures, device_state: device_state, events: events} = new_state,
         device_state_before
       ) do
    failures =
      if device_state == :error do
        failures + 1
      else
        failures
      end

    events = [format_event(device_state, device_state_before) | events]

    %{new_state | device_state: device_state, failures: failures, events: events}
  end

  defp broadcast_if_changed(%__MODULE__{device_state: d}, d), do: :ok

  defp broadcast_if_changed(%__MODULE__{} = state, _) do
    broadcast!(Iotsim.PubSub, "device_state/all", {state.id, state.device_state})
    broadcast!(Iotsim.PubSub, "device_state/detailed/#{state.id}", state)
    :ok
  end
end
