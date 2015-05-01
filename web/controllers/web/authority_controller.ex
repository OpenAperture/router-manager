defmodule RouterManager.AuthorityController do
  use RouterManager.Web, :controller

  import Ecto.Query

  alias RouterManager.Authority
  alias RouterManager.DeletedAuthority
  alias RouterManager.Route

  plug :scrub_params, "authority" when action in [:create, :update]
  plug :action

  def index(conn, _params) do
    authorities = Repo.all(Authority)
    render conn, "index.html", authorities: authorities
  end

  def new(conn, _params) do
    changeset = Authority.changeset(%Authority{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"authority" => authority_params}) do
    changeset = Authority.changeset(%Authority{}, authority_params)

    if changeset.valid? do
      Repo.insert(changeset)

      conn
      |> put_flash(:info, "Authority created successfully.")
      |> redirect(to: web_authority_path(conn, :index))
    else
      render conn, "new.html", changeset: changeset
    end
  end

  def show(conn, %{"id" => id}) do
    case Repo.get(Authority, id) do
      nil ->
        render conn, "not_found.html"
      authority ->
        render conn, "show.html", authority: authority
    end
  end

  def edit(conn, %{"id" => id}) do
    authority = Repo.get(Authority, id)
    changeset = Authority.changeset(authority)
    render conn, "edit.html", authority: authority, changeset: changeset
  end

  def update(conn, %{"id" => id, "authority" => authority_params}) do
    case Repo.get(Authority, id) do
      nil ->
        render conn, "not_found.html"
      authority ->
        changeset = Authority.changeset(authority, authority_params)

        if changeset.valid? do
          Repo.update(changeset)

          conn
          |> put_flash(:info, "Authority updated successfully.")
          |> redirect(to: web_authority_path(conn, :index))
        else
          render conn, "edit.html", authority: authority, changeset: changeset
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Repo.get(Authority, id) do
      nil ->
        render conn, "not_found.html"
      authority ->
        Repo.transaction(fn ->
          Route
          |> where([r], r.authority_id == ^id)
          |> Repo.delete_all

          # Create a deleted_authority record
          %DeletedAuthority{}
          |> DeletedAuthority.changeset(%{hostname: authority.hostname, port: authority.port})
          |> Repo.insert

          Repo.delete(authority)
        end)

        conn
        |> put_flash(:info, "Authority deleted successfully.")
        |> redirect(to: web_authority_path(conn, :index))
    end
  end
end
