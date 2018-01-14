defmodule DotLocal do
  defmodule Proxy do
    def init(backend), do: backend

    def call(conn, backend) do
      backend.call(conn, [])
    end
  end

  require Logger

  @doc """
  ## Options:

  * `:backend` - plug to forwards requests to
  * `:service` - name of the service
  * `:https` - whether or not to use HTTPS, defaults to `true`
  * `:keyfile` - path to keyfile, defaults to one included with DotLocal
  * `:cerfile` - path to certfile, defaults to one included with DotLocal
  """
  def child_spec(opts) do
    backend = Keyword.fetch!(opts, :backend)
    service = Keyword.fetch!(opts, :service) |> Atom.to_string() |> String.replace("_", "-")
    https? = Keyword.get(opts, :https, false)
    port = Keyword.get(opts, :port, (if https?, do: 8443, else: 8080))

    register_service(service, port)

    if https? do
      Plug.Adapters.Cowboy.child_spec(:https, Proxy, backend, Keyword.merge([port: port], https_opts(opts)))
    else
      Plug.Adapters.Cowboy.child_spec(:http, Proxy, backend, [port: port])
    end
  end

  defp https_opts(opts) do
    priv_dir = :code.priv_dir(:dotlocal)
    keyfile = Keyword.get(opts, :keyfile, priv_dir ++ '/server.key')
    certfile = Keyword.get(opts, :certfile, priv_dir ++ '/server.crt')

    [
      keyfile: keyfile,
      certfile: certfile
    ]
  end

  defp register_service(name, port) do
    Logger.info("dotlocal: registering service #{name} on #{ip()}:#{port}")
    # TODO: we call this async because dns-d blocks,
    #       we should use a dnssd binding instead of cli
    async_cmd!(~w(dns-sd -P #{name} _http._tcp local #{port} #{name}.local #{ip()}))
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
