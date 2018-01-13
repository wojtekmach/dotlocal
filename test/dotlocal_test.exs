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
    name = "hello-test2"
    port = 4001

    DotLocal.Proxy.start(8888)
    start_hello(port)
    DotLocal.register(name, port)

    assert HTTPoison.get!("http://#{name}.local").body == "Hello world"
  end

  defp start_hello(port) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Hello, [], [port: port])
    ]
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
