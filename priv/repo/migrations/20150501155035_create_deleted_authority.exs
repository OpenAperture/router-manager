defmodule RouterManager.Repo.Migrations.CreateDeletedAuthority do
  use Ecto.Migration

  def change do
    create table(:deleted_authorities) do
      add :hostname, :string
      add :port, :integer

      timestamps
    end

    create index(:deleted_authorities, [:updated_at])
  end
end
