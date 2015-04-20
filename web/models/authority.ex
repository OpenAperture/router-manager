defmodule RouterManager.Authority do
  use RouterManager.Web, :model

  schema "authorities" do
    field :hostname,  :string
    field :port,      :integer

    has_many :routes, RouterManager.Route

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
    |> validate_length(:hostname, min: 1)
    |> validate_inclusion(:port, 1..65535, message: "invalid port number")
  end
end
