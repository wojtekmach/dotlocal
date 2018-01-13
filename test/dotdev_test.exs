defmodule Hello do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello world")
  end
end

defmodule DotdevTest do
  use ExUnit.Case

  test "greets the world" do
    assert {:error, _} = HTTPoison.get("http://localhost:4001/")

    start_hello()

    assert HTTPoison.get!("http://localhost:4001/").body == "Hello world"
  end

  defp start_hello() do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Hello, [], [port: 4001])
    ]
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
