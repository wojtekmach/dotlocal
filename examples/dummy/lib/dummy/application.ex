defmodule Dummy.Application do
  use Application

  def start(_type, _args) do
    children = [
      DummyWeb.Endpoint
      # DotLocal.child_spec(service: :dummy, backend: DummyWeb.Endpoint, https: true, port: 8443)
    ]

    opts = [strategy: :one_for_one, name: Dummy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    DummyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
