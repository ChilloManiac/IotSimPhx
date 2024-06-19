defmodule IotSim.Device.Event do
  defstruct message: nil, timestamp: nil
end

defmodule Iotsim.Device.DeviceSim do
  use GenServer
  require Logger

  import Phoenix.PubSub

  defstruct id: nil, device_state: :starting, failures: 0, events: []

  @states [:starting, :running, :error, :broken]

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  def get_state(id, type \\ :simple) do
    id
    |> via_tuple()
    |> GenServer.call({:get_state, type})
  end

  def set_state(id, state) when state in @states do
    id
    |> via_tuple()
    |> GenServer.cast({:set_state, state})
  end

  def reset_failures(id) do
    id
    |> via_tuple()
    |> GenServer.cast(:reset_failures)
  end

  ## GenServer callbacks

  @impl true
  def init(id) do
    Iotsim.Ticker.subscribe()
    state = %__MODULE__{id: id}
    broadcast!(Iotsim.PubSub, "device_state/all", {:device_state_changed, id, state.device_state})
    {:ok, state}
  end

  @impl true
  def handle_call(
        {:get_state, :simple},
        _from,
        %__MODULE__{id: id, device_state: device_state} = state
      ) do
    {:reply, {id, device_state}, state}
  end

  @impl true
  def handle_call({:get_state, _}, _from, state) do
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

  @impl true
  def handle_cast({:set_state, new_state}, %__MODULE__{} = state) do
    next_state =
      state
      |> Map.put(:device_state, new_state)
      |> Map.update!(:events, &[admin_event(new_state, state.device_state) | &1])

    broadcast!(
      Iotsim.PubSub,
      "device_state/all",
      {:device_state_changed, state.id, state.device_state}
    )

    broadcast!(Iotsim.PubSub, "device_state/detailed/#{state.id}", {:detailed_state, state})
    {:noreply, next_state}
  end

  @impl true
  def handle_cast(:reset_failures, %__MODULE__{} = state) do
    next_state = Map.put(state, :failures, 0)

    broadcast!(
      Iotsim.PubSub,
      "device_state/all",
      {:device_state_changed, state.id, state.device_state}
    )

    broadcast!(Iotsim.PubSub, "device_state/detailed/#{state.id}", {:detailed_state, state})
    {:noreply, next_state}
  end

  ## Private functions

  defp event(device_state, device_state_before) do
    %{
      message: "Device state changed from #{device_state_before} to #{device_state}",
      timestamp: DateTime.utc_now()
    }
  end

  defp admin_event(device_state, device_state_before) do
    %{
      message: "Admin changed device state from #{device_state_before} to #{device_state}",
      timestamp: DateTime.utc_now()
    }
  end

  defp via_tuple(id) do
    {:via, Registry, {Iotsim.Registry, id}}
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

    events = [event(device_state, device_state_before) | events]

    %{new_state | device_state: device_state, failures: failures, events: events}
  end

  defp broadcast_if_changed(%__MODULE__{device_state: d}, d), do: :ok

  defp broadcast_if_changed(%__MODULE__{} = state, _) do
    broadcast!(
      Iotsim.PubSub,
      "device_state/all",
      {:device_state_changed, state.id, state.device_state}
    )

    broadcast!(Iotsim.PubSub, "device_state/detailed/#{state.id}", {:detailed_state, state})
    :ok
  end
end
