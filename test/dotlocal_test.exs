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
    port = 8888

    opts = [strategy: :one_for_one, name: Hello.Supervisor]

    children = [
      DotLocal.child_spec(name, Hello, port, https: true, otp_app: :dotlocal)
    ]

    Supervisor.start_link(children, opts)

    assert get!("https://#{name}.local:#{port}").body == "Hello world"
  end

  defp get!(url) do
    HTTPoison.get!(url, [], ssl: [{:versions, [:"tlsv1.2"]}])
  end
end
