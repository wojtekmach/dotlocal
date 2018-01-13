defmodule DotLocal do
  defmodule Proxy do
    def init(backend), do: backend

    def call(conn, backend) do
      backend.call(conn, [])
    end
  end

  require Logger

  def child_spec(service_name, backend, proxy_port) do
    register_service(service_name, proxy_port)
    Logger.info("Starting DotLocal.Proxy on port #{proxy_port}")
    Plug.Adapters.Cowboy.child_spec(:http, Proxy, backend, [port: proxy_port])
  end

  defp register_service(name, port) do
    Logger.info("Registering service #{name} on #{ip()}:#{port}")
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
