defmodule RouterManager.Repo.Migrations.AddUniqueIndexToAuthoritiesTable do
  use Ecto.Migration

  def change do
    create index(:authorities, ["lower(hostname)", :port], unique: true)
  end
end
