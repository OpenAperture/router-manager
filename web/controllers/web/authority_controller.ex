defmodule RouterManager.AuthorityController do
  use RouterManager.Web, :controller

  alias RouterManager.Authority

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
    authority = Repo.get(Authority, id)
    render conn, "show.html", authority: authority
  end

  def edit(conn, %{"id" => id}) do
    authority = Repo.get(Authority, id)
    changeset = Authority.changeset(authority)
    render conn, "edit.html", authority: authority, changeset: changeset
  end

  def update(conn, %{"id" => id, "authority" => authority_params}) do
    authority = Repo.get(Authority, id)
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

  def delete(conn, %{"id" => id}) do
    authority = Repo.get(Authority, id)
    Repo.delete(authority)

    conn
    |> put_flash(:info, "Authority deleted successfully.")
    |> redirect(to: web_authority_path(conn, :index))
  end
end
