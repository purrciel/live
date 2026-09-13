defmodule Live.Repo do
  use Ecto.Repo,
    otp_app: :live,
    adapter: Ecto.Adapters.Postgres
end
