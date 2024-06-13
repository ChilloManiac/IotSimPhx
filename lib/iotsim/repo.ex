defmodule Iotsim.Repo do
  use Ecto.Repo,
    otp_app: :iotsim,
    adapter: Ecto.Adapters.Postgres
end
