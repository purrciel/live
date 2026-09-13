defmodule Live.Repo.Migrations.AddChannelFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
      add :bio, :text
      add :avatar_url, :string
      add :stream_title, :string, default: "Welcome to my stream!"
      add :category, :string, default: "Just Chatting"
    end

    create unique_index(:users, [:username])
  end
end
