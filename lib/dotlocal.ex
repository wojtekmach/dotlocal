defmodule DotLocal do
  def register(name, port) do
    # TODO: we call this async because dns-d blocks,
    #       we should use a dnssd binding instead of cli
    async_cmd!(~w(dns-sd -P #{name} _http._tcp local #{port} #{name}.local #{ip()}))
  end

  def proxy_cmd() do
    ~s{echo "rdr pass inet proto tcp from any to any port 80 -> 127.0.0.1 port 8888" | sudo pfctl -ef -}
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
