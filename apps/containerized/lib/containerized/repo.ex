defmodule Containerized.Repo do
  use Ecto.Repo,
    otp_app: :containerized,
    adapter: Ecto.Adapters.Postgres
end
