defmodule Live.Repo.Migrations.AddStreamKeyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stream_key, :string
    end

    create unique_index(:users, [:stream_key])
  end
end
