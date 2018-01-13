# DotLocal

Serve your web app as <http://myapp.local> with minimal configuration.

## Installation

Add to deps:

```elixir
def deps do
  [
    {:dotlocal, github: "wojtekmach/dotlocal"}
  ]
end
```

Add to supervision tree:

```elixir
defmodule MyApp.Application do
  def start(_type, _opts) do
    # ...

    children = [
      supervisor(Hexpm.Web.Endpoint, []),
      DotLocal.child_spec("myapp", MyAppWeb.Endpoint, 8888)
    ]

    # ...
end
```

Open <http://myapp.local:8888>.

It's convenient to forward port 80 to 8888 so that we can access this with just <http://myapp.local>; on macOS 10.12+ run:

```
echo "rdr pass inet proto tcp from any to any port 80 -> 127.0.0.1 port #{port}" | sudo pfctl -ef -
```
