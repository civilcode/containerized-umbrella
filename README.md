# Containerized.Umbrella

## To install on the host

- Docker
- Git + hub
- make

## To-do:

- create umbrella within the container
- use official elixir alpine image
- add bin/app_setup and call it from postCreateCommand
- COMPOSE_FILE variable?

- bash history
- bash instead of ash
- observer (works, but if we were using an image other than bitwalker/erlang (with observer compiled in erlang), we could use it directory in VS Code - would just need to see the DISPLAY variable)
- use ENV variables to configure remote container??? (https://code.visualstudio.com/docs/remote/containers-advanced)
- put Docker dev config under .devcontainer???
- postCreateCommand to run commands after the container has been built (make app.setup)


## Instructions to create a sample Phoenix app and setting-up VSCode Remote

Create new Phoenix app (do not install dependencies when asked):

```
mix phx.new ../containerized --umbrella --database postgres
cd ../containerized_umbrella
git init .
git add .
git commit -m "Initial commit"
```

Set-up VSCode development container:

```
echo "\n.elixir_ls" >> .gitignore
mkdir .vscode
cat <<"TEXT" > .vscode/settings.json
{
  "editor.formatOnSave": true
}
TEXT
```

```
mkdir .devcontainer
cat <<"TEXT" > .devcontainer/devcontainer.json
{
  "name": "containerized",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/app",
  "appPort": 4000,
  "shutdownAction": "stopCompose",
  "extensions": [
    "elixir-lsp.elixir-ls",
    "ms-vscode.atom-keybindings",
    "eamodio.gitlens",
    "yzhang.markdown-all-in-one"
  ]
}
TEXT
```

```
cat <<"TEXT" > docker-compose.yml
version: '3'

services:
  db:
    image: postgres:10.4
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      PGDATA: /pgdata
    volumes:
      - pgdata:/pgdata

  app:
    image: containerized-dev
    container_name: containerized-dev__app
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      # Let Docker persist dependencies and builds:
      # * if we blow away Docker this can be easily recreated
      # * it keeps all build concerns separate from the host operating system
      # * for compiled dependencies, stop conflicts with different host OS
      # * maps to a subset of directories in .gitignore
      - .:/app:cached
      - build:/app/_build:cached
      - deps:/app/deps:cached
      - node_modules:/app/apps/containerized_web/assets/node_modules:cached
      - static:/app/apps/containerized_web/priv/static:cached
    ports:
      - "4000:4000"
    depends_on:
      - db
    tty: true

  erlang:
    # For using observer through X11 (xquartz on Mac)
    image: erlang:latest
    command: sleep infinity

# volumes defined for use in above configuration
volumes:
  build:
  deps:
  node_modules:
  pgdata:
  static:
TEXT
```

```
cat <<"TEXT" > Dockerfile.dev
FROM bitwalker/alpine-elixir-phoenix:1.9.2

RUN mix do local.hex --force, local.rebar --force

CMD ["/bin/bash"]
TEXT
```

Text building the dev container:

```
> docker-compose build --force-rm --no-cache
```

Replace database server name in configuration:

```
sed -i "" 's/localhost/db/g' config/test.exs
sed -i "" 's/localhost/db/g' config/dev.exs
```

Start VSCode

```
code .
```

Then click on "Reopen in Container". Once the container is ready, it will reopen and you it will start building the Elixir PLT files. Then, in the VSCode terminal:

```
mix deps.get
mix test
mix ecto.create
(cd /app/apps/containerized_web/assets/ && npm install)
mix phx.server
```

Open http://localhost:4000 in your local browser and confirm the Phoenix splash page shows up.

Test the file sync between the host and the container:

```
sed -i "" 's/Phoenix/Containerized/g' apps/containerized_web/lib/containerized_web/templates/page/index.html.eex
```

Phoenix should pick up the change in the container and refresh the browser page. This demonstrate that files are being synced between the host and the container.

The Remote Containers extension takes care of the git configuration. So you should be able to use git in the container with your local credentials and configuration. More details here: https://code.visualstudio.com/docs/remote/containers#_sharing-git-credentials-with-your-container

Tips:

- If you change the devcontainer.json file, click on the remote button on the bottom left to rebuild the container.
