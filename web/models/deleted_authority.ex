defmodule RouterManager.DeletedAuthority do
  use RouterManager.Web, :model

  schema "deleted_authorities" do
    field :hostname, :string
    field :port, :integer

    timestamps
  end

  @required_fields ~w(hostname port)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If `params` are nil, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ nil) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
