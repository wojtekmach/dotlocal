# DotLocal

Serve your web app as <http://myapp.local> with minimal configuration.

## Installation

Add to deps:

```elixir
def deps do
  [
    {:dotlocal, github: "wojtekmach/dotlocal", only: :dev}
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

## HTTPS

In order to access your app over HTTPS follow these steps:

1. Add `https: true` and `:otp_app` options in your supervision tree:

   ```
   DotLocal.child_spec("myapp", MyAppWeb.Endpoint, 8888, https: true, otp_app: :myapp)
   ```

   `:otp_app` option is used to locate certificate files. You can use certificates that
   DotLocal ships with by passing `otp_app: :dotlocal`.

2. Optionally Create `priv/dotlocal/server.key` and `priv/dotlocal/server.crt` files

   To create self-signed certificates, run following commands (based on https://devcenter.heroku.com/articles/ssl-certificate-self)

   ```
   openssl genrsa -des3 -passout pass:x -out priv/dotlocal/server.pass.key 2048
   openssl rsa -passin pass:x -in priv/dotlocal/server.pass.key -out priv/dotlocal/server.key
   rm priv/dotlocal/server.pass.key

   # it's ok to leave all options as default/blank
   openssl req -new -key priv/dotlocal/server.key -out priv/dotlocal/server.csr

   openssl x509 -req -sha256 -days 365 -in priv/dotlocal/server.csr -signkey priv/dotlocal/server.key -out priv/dotlocal/server.crt
   ```

If you are using port forwarding described in previous section, make sure to forward port 443 for HTTPS.
