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
  test "http" do
    name = "hello-http"
    port = 8080

    opts = [
      service: :hello_http,
      backend: Hello,
      http: [port: port]
    ]

    children = DotLocal.child_specs(opts)
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)

    assert get!("http://#{name}.local:#{port}").body == "Hello world"
  end

  @tag :integration
  test "https" do
    name = "hello-https"
    port = 8443

    opts = [
      service: :hello_https,
      backend: Hello,
      https: [port: port]
    ]

    children = DotLocal.child_specs(opts)
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)

    assert get!("https://#{name}.local:#{port}").body == "Hello world"
  end

  defp get!(url) do
    HTTPoison.get!(url, [], ssl: [{:versions, [:"tlsv1.2"]}])
  end
end
