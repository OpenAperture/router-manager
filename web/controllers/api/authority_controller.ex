defmodule RouterManager.Api.AuthorityController do
  require Logger
  use RouterManager.Web, :controller
  import RouterManager.ControllerHelper
  import Ecto.Query
  import RouterManager.Router.Helpers
  import RouterManager.ParamsPlug

  alias RouterManager.Authority
  alias RouterManager.Endpoint
  alias RouterManager.Route

  plug :parse_as_integer, "id"
  plug :parse_as_integer, {"port", 400}
  plug :validate_param, {"hostname", &Kernel.is_binary/1}
  plug :action

  @sendable_fields [:id, :hostname, :port, :inserted_at, :updated_at]

  # GET /api/authorities?authority=somehost%3Asomeport
  def index(conn, %{"authority" => authority}) do
    case parse_authority(authority) do
      {:ok, hostname, port} ->
        case get_authority_by_hostname_and_port(hostname, port) do
          nil ->
            resp conn, :not_found, ""
          authority ->
            json conn, to_sendable(authority, @sendable_fields)
        end
      :error ->
        resp conn, :bad_request, ""
    end
  end

  # GET /api/authorities
  def index(conn, _params) do
    authorities = Authority
                  |> Repo.all
                  |> Enum.map(&to_sendable(&1, @sendable_fields))

    json conn, authorities
  end

  # GET /api/authorities/:id
  def show(conn, %{"id" => id}) do
    case Repo.get(Authority, id) do
      nil -> resp conn, :not_found, ""
      host -> json conn, to_sendable(host, @sendable_fields)
    end
  end

  # DELETE /api/authorities/:id
  def delete(conn, %{"id" => id}) do
    case Repo.get(Authority, id) do
      nil -> resp conn, :not_found, ""
      host ->
        result = Repo.transaction(fn ->
          Route
          |> where([r], r.authority_id == ^id)
          |> Repo.delete_all

          Repo.delete(host)
        end)

        case result do
          {:ok, _} -> resp conn, :no_content, ""
          error ->
            Logger.error "Error deleting authority: #{inspect error}"
            resp conn, :internal_server_error, ""
        end
    end
  end

  # POST /api/authorities
  def create(conn, %{"hostname" => hostname, "port" => port} = _params) when hostname != nil and port != nil do
    case get_authority_by_hostname_and_port(hostname, port) do
      nil ->
        changeset = Authority.changeset(%Authority{}, %{hostname: hostname, port: port})
        if changeset.valid? do
          authority = Repo.insert(changeset)
          path = api_authority_path(Endpoint, :show, authority)

          conn
          |> put_resp_header("location", path)
          |> resp(:created, "")
        else
          conn
          |> put_status(:bad_request)
          |> json inspect(changeset.errors)
        end
      _authority ->
        resp(conn, :conflict, "")
    end
  end

  # This action only matches if a param is missing
  def create(conn, _params) do
    Plug.Conn.resp(conn, :bad_request, "hostname and port are required")
  end

  # PUT/PATCH /api/authorities/:id
  def update(conn, %{"id" => id} = params) do
    case Repo.get(Authority, id) do
      nil -> resp conn, :not_found, ""
      authority ->
        changeset = Authority.changeset(authority, params)
        if changeset.valid? do
          {_source, hostname} = Ecto.Changeset.fetch_field(changeset, :hostname)
          {_source, port} = Ecto.Changeset.fetch_field(changeset, :port)

          existing = get_authority_by_hostname_and_port(hostname, port)

          if existing == nil || existing.id == authority.id do
            Repo.update(changeset)
            path = api_authority_path(Endpoint, :show, authority)

            conn
            |> put_resp_header("location", path)
            |> resp(:no_content, "")
          else
            resp(conn, :conflict, "")
          end
        else
          conn
          |> put_status(:bad_request)
          |> json inspect(changeset.errors)
        end
    end
  end

  @spec get_authority_by_hostname_and_port(String.t, integer) :: Authority.t | nil
  defp get_authority_by_hostname_and_port(hostname, port) do
    Authority
    |> where([a], fragment("lower(?) = lower(?)", a.hostname, ^hostname))
    |> where([a], a.port == ^port)
    |> Repo.one
  end

  @spec parse_authority(String.t) :: {:ok, String.t, integer} | :error
  defp parse_authority(authority) do
    colon_regex = ~r/(?<hostname>.*):(?<port>\d+)$/
    urlencoded_regex = ~r/(?<hostname>.*)%3[aA](?<port>\d+)$/

    cond do
      Regex.match?(colon_regex, authority) ->
        captures = Regex.named_captures(colon_regex, authority)
        {:ok, captures["hostname"], String.to_integer(captures["port"])}

      Regex.match?(urlencoded_regex, authority) ->
        captures = Regex.named_captures(urlencoded_regex, authority)
        {:ok, captures["hostname"], String.to_integer(captures["port"])}

      true -> :error
    end
  end
end