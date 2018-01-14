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

  * `:https` - whether or not to use HTTPS, defaults to `true`
  * `:otp_app` - the name of the OTP app
  * `:keyfile` - path to keyfile, defaults to `priv/dotlocal/server.key` for given OTP app
  * `:cerfile` - path to certfile, defaults to `priv/dotlocal/certfile.key` for given OTP app
  """
  def child_spec(service_name, backend, proxy_port, opts \\ []) do
    register_service(service_name, proxy_port)

    if opts[:https] do
      Logger.info("dotlocal: starting proxy on https://#{service_name}.local:#{proxy_port}")
      https_opts = https_opts(opts) |> Keyword.put(:port, proxy_port)
      Plug.Adapters.Cowboy.child_spec(:https, Proxy, backend, https_opts)
    else
      Logger.info("dotlocal: starting proxy on http://#{service_name}.local:#{proxy_port}")
      http_opts = [port: proxy_port]
      Plug.Adapters.Cowboy.child_spec(:http, Proxy, backend, http_opts)
    end
  end

  defp https_opts(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    priv_dir = to_string(:code.priv_dir(otp_app))
    keyfile = Keyword.get(opts, :keyfile, priv_dir <> "/dotlocal/server.key")
    certfile = Keyword.get(opts, :keyfile, priv_dir <> "/dotlocal/server.crt")

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
