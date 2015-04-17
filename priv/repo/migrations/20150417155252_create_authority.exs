defmodule RouterManager.Repo.Migrations.CreateAuthority do
  use Ecto.Migration

  def change do
    create table(:authorities) do
      add :hostname, :string,  null: false
      add :port,     :integer, null: false

      timestamps
    end
  end
end
