defmodule DotLocal.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    opts = Application.get_all_env(:dotlocal)

    if !opts[:service] && !opts[:backend] do
      raise ArgumentError, """
      DotLocal application is misconfigured

      Add configuration to `config/dev.exs`:

          config :dotlocal,
            service: :myapp,
            backend: MyApp.Endpoint,
            http: [port: 8080],
            https: [port: 8443]

      Or, configure dependency not to start the application:

          defp deps do
            # ...
            {:dotlocal, ">= 0.0.0", only: :dev, runtime: false}
            # ...
          end
      """
    end

    children = DotLocal.child_specs(opts)

    opts = [strategy: :one_for_one, name: DotLocal.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule DotLocal.Proxy do
  @moduledoc false

  def init(backend), do: backend

  def call(conn, backend) do
    backend.call(conn, [])
  end
end

defmodule DotLocal do
  @moduledoc """
  DotLocal allows to serve your Web app as myapp.local with minimal configuration.

  DotLocal can be either automatically or manually started.

  ## Automatic start

  By default, when we add DotLocal as dependency to `mix.exs`:

      defp deps do
        ...
        {:dotlocal, ">= 0.0.0", only: :dev}
        ...
      end

  it will be started automatically in it's own supervision tree and needs to be
  configured e.g. in `config/dev.exs`:

      config :dotlocal,
        service: :myapp,
        backend: MyApp.Endpoint,
        http: [port: 8080],
        https: [port: 8443]

  The above configuration will launch two Cowboy servers proxying requests to `MyApp.Endpoint`
  on ports 8080 and 8443 respectively.

  ## Manual start

  Alternatively, DotLocal can be started manually in your app's supervision tree:

      defp deps do
        # ...
        {:dotlocal, ">= 0.0.0", only: :dev, runtime: false}
        # ...
      end

  (Note: `runtime: false`.)

  And then in `application.ex`:

      defmodule MyApp.Application do
        use Application

        def start(_type, _args) do
          # ...

          opts = [
            service: :myapp,
            backend: MyApp.Endpoint,
            http: [port: 8080],
            https: [port: 8443]
          ]

          children = [
            MyApp.Endpoint,
          ] ++ DotLocal.child_specs(opts)

          # ...
        end
      end
  """

  alias DotLocal.Proxy
  require Logger

  @doc """
  ## Options:

  * `:backend` - plug to forward requests to
  * `:service` - name of the service
  * `:http` - keywords list of HTTP options
  * `:https` - keywords list of HTTPS options
  """
  def child_specs(opts) do
    service_opts = %{
      backend: Keyword.fetch!(opts, :backend),
      name: Keyword.fetch!(opts, :service) |> Atom.to_string() |> String.replace("_", "-")
    }

    if !opts[:http] && !opts[:https] do
      raise ArgumentError, "at least one :http or :https adapter configuration must be specified "
    end

    serve_endpoints? =
      Application.get_env(:phoenix, :serve_endpoints) ||
        Application.get_env(:dotlocal, :serve_endpoints)

    if serve_endpoints? do
      child_specs(opts, service_opts, [])
    else
      []
    end
  end

  defp child_specs([{adapter, opts} | tail], service_opts, acc)
       when adapter in [:http, :https] do
    child_specs(tail, service_opts, [child_spec(adapter, opts, service_opts) | acc])
  end

  defp child_specs([_ | tail], service_opts, acc) do
    child_specs(tail, service_opts, acc)
  end

  defp child_specs([], _service_opts, acc) do
    Enum.reverse(acc)
  end

  defp child_spec(:http, http_opts, service_opts) do
    register_service(:http, service_opts.name, http_opts[:port])
    Plug.Adapters.Cowboy.child_spec(:http, Proxy, service_opts.backend, http_opts)
  end

  defp child_spec(:https, https_opts, service_opts) do
    register_service(:https, service_opts.name, https_opts[:port])
    priv_dir = :code.priv_dir(:dotlocal)

    https_opts =
      https_opts
      |> Keyword.put_new(:keyfile, priv_dir ++ '/server.key')
      |> Keyword.put_new(:certfile, priv_dir ++ '/server.crt')

    Plug.Adapters.Cowboy.child_spec(:https, Proxy, service_opts.backend, https_opts)
  end

  # TODO: do not call this function in child specs!
  defp register_service(protocol, name, port) do
    Logger.info("dotlocal: registering #{protocol}://#{name}.local:#{port}")
    # TODO: we call this async because dns-d blocks,
    #       we should use a dnssd binding instead of cli
    async_cmd!(~w(dns-sd -P #{name} _#{protocol}._tcp local #{port} #{name}.local #{ip()}))
  end

  defp ip() do
    {:ok, [{ip, _, _} | _]} = :inet.getif()
    Enum.map_join(Tuple.to_list(ip), ".", &to_string/1)
  end

  defp async_cmd!(args) do
    Task.async(fn -> cmd!(args) end)
  end

  defp cmd!([cmd | args]) do
    System.cmd(cmd, args, into: IO.stream(:stdio, :line))
  end
end
