defmodule RouterManager.Repo.Migrations.AddUniqueIndexToRoutesTable do
  use Ecto.Migration

  def change do
    create index(:routes, [:authority_id, "lower(hostname)", :port], unique: true)
  end
end
