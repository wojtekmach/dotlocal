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
    name = "hello-test"

    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    children = [
      DotLocal.child_spec(name, Hello, 8888)
    ]
    Supervisor.start_link(children, opts)

    assert HTTPoison.get!("http://#{name}.local").body == "Hello world"
  end
end
