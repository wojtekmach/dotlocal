# DotLocal

Serve your web app as myapp.local with minimal configuration.

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
      supervisor(MyAppWeb.Endpoint, []),
      DotLocal.child_spec(service: :myapp, backend: MyAppWeb.Endpoint, port: 8080)
    ]

    # ...
  end
end
```

Open <http://myapp.local:8080>.

It's convenient to forward port 80 to 8080 so that we can access this with just <http://myapp.local>; on macOS 10.12+ run:

```
echo "rdr pass inet proto tcp from any to any port 80 -> 127.0.0.1 port 8080" | sudo pfctl -ef -
```

## HTTPS

The simplest way to listen on HTTPS is to change `DotLocal.child_spec/1` call from previous section to be:

```elixir
DotLocal.child_spec(service: :myapp, backend: MyAppWeb.Endpoint, https: true, port: 8443)
```

Open <https://myapp.local:8443>.

If you are using port forwarding described in previous section, make sure to forward port 443 for HTTPS:

```
echo "rdr pass inet proto tcp from any to any port 443 -> 127.0.0.1 port 8443" | sudo pfctl -ef -
```

## HTTPS customization

DotLocal ships with a sample, self-signed key and certificate that are used by default.

Below, we'll generate another self-signed pair and configure DotLocal to use it.
This guide is bbased on https://devcenter.heroku.com/articles/ssl-certificate-self.

Run following commands:

```
openssl genrsa -des3 -passout pass:x -out priv/dotlocal/server.pass.key 2048
openssl rsa -passin pass:x -in priv/dotlocal/server.pass.key -out priv/dotlocal/server.key
rm priv/dotlocal/server.pass.key

# it's ok to leave all options as default/blank
openssl req -new -key priv/dotlocal/server.key -out priv/dotlocal/server.csr

openssl x509 -req -sha256 -days 365 -in priv/dotlocal/server.csr -signkey priv/dotlocal/server.key -out priv/dotlocal/server.crt
```

Update child spec to be:

```elixir
DotLocal.child_spec(
  service: :myapp,
  backend: MyAppWeb.Endpoint,
  port: 8443,
  https: true,
  keyfile: :code.priv_dir(:myapp) ++ '/dotlocal/server.key',
  certfile: :code.priv_dir(:myapp) ++ '/dotlocal/server.crt'
)
```

## License

Copyright 2018 Wojciech Mach

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
