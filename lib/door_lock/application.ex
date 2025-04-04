defmodule DoorLock.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DoorLockWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:door_lock, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DoorLock.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: DoorLock.Finch},
      # Start a worker by calling: DoorLock.Worker.start_link(arg)
      # {DoorLock.Worker, arg},
      # Start to serve requests, typically the last entry
      DoorLockWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DoorLock.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DoorLockWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
