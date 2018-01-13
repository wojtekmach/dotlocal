defmodule Hello do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello world")
  end
end

defmodule DotLocalTest do
  use ExUnit.Case

  @tag :integration
  test "greets the world" do
    async_cmd!(~w(dns-sd -P hello-test _http._tcp local 4001 hello-test.local 192.168.0.200))
    start_hello()

    assert HTTPoison.get!("http://hello-test.local:4001/").body == "Hello world"
  end

  defp start_hello() do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Hello, [], [port: 4001])
    ]
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp async_cmd!(args) do
    Task.async(fn -> cmd!(args) end)
  end

  defp cmd!([cmd | args]) do
    System.cmd(cmd, args, into: IO.stream(:stdio, :line))
  end
end
