defmodule RouterManager.Route do
  use RouterManager.Web, :model

  schema "routes" do
    belongs_to :authority,    RouterManager.Authority
    field :hostname,          :string
    field :port,              :integer
    field :secure_connection, :boolean, default: false

    timestamps
  end

  @required_fields ~w(authority_id hostname port secure_connection)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If `params` are nil, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ nil) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:hostname, min: 1)
    |> validate_inclusion(:port, 1..65535, message: "invalid port number")
  end
end
