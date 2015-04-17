defmodule RouterManager.Api.AuthorityController do
  use RouterManager.Web, :controller
  import RouterManager.ControllerHelper
  import Ecto.Query

  alias RouterManager.Authority

  plug :scrub_params, "authority" when action in [:create, :update]
  plug :action

  @sendable_fields [:id, :hostname, :port, :inserted_at, :updated_at]

  # GET /api/authorities?authority=somehost%3Asomeport
  def index(conn, %{"authority" => authority}) do
    case parse_authority(authority) do
      {:ok, hostname, port} ->
        query = Authority
                |> where([a], fragment("lower(?) = lower(?)", a.hostname, ^hostname))
                |> where([a], a.port == ^port)

        case Repo.one(query) do
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
        Repo.delete(host)
        resp conn, :no_content, ""
    end
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