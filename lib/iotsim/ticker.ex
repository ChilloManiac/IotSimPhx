defmodule Iotsim.Ticker do
  require Logger
  use GenServer
  import Phoenix.PubSub

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def subscribe() do
    subscribe(Iotsim.PubSub, "tick")
  end

  @impl true
  def init(_state) do
    Process.send_after(self(), :tick, 5000)
    {:ok, nil}
  end

  @impl true
  def handle_info(:tick, _state) do
    broadcast!(Iotsim.PubSub, "tick", :tick)
    Logger.debug("Tick")
    Process.send_after(self(), :tick, 5000)
    {:noreply, nil}
  end
end
