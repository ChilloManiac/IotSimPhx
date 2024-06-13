defmodule Iotsim.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      IotsimWeb.Telemetry,
      Iotsim.Repo,
      {DNSCluster, query: Application.get_env(:iotsim, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Iotsim.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Iotsim.Finch},
      # Start a worker by calling: Iotsim.Worker.start_link(arg)
      # {Iotsim.Worker, arg},
      # Start to serve requests, typically the last entry
      IotsimWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Iotsim.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IotsimWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
