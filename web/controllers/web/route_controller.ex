defmodule RouterManager.RouteController do
  use RouterManager.Web, :controller

  import Ecto.Query

  alias RouterManager.Route
  alias RouterManager.Authority

  plug :scrub_params, "route" when action in [:create, :update]
  plug :action

  def index(conn, %{"authority_id" => authority_id}) do
    query = Authority
            |> where([a], a.id == ^authority_id)
            |> preload(:routes)

    case Repo.one(query) do
      nil ->
        render conn, "authority_not_found.html"
      authority ->
        render conn, "index.html", routes: authority.routes, authority: authority
    end
  end

  def new(conn, %{"authority_id" => authority_id}) do
    case Repo.get(Authority, authority_id) do
      nil ->
        render conn, "authority_not_found.html"
      authority ->
        changeset = Route.changeset(%Route{})
        render conn, "new.html", changeset: changeset, authority: authority
    end    
  end

  def create(conn, %{"route" => route_params, "authority_id" => authority_id}) do
    query = Authority
            |> join(:left, [a], r in Route, r.authority_id == a.id and r.port == ^route_params["port"] and fragment("lower(?) = lower(?)", r.hostname, ^route_params["hostname"]))
            |> where([a, r], a.id == ^authority_id)
            |> select([a, r], {a, r})

    case Repo.one(query) do
      nil ->
        render conn, "authority_not_found.html"
      {authority, nil} ->
        changeset = Route.changeset(%Route{authority_id: authority.id}, route_params)
        if changeset.valid? do
          Repo.insert(changeset)

          conn
          |> put_flash(:info, "Route created successfully.")
          |> redirect(to: web_authority_route_path(conn, :index, authority.id))
        else
          render conn, "new.html", changeset: changeset, authority: authority
        end
      {authority, _route} ->
        changeset = Route.changeset(%Route{authority_id: authority.id}, route_params)
        route_string = "#{route_params["hostname"]}:#{route_params["port"]}"
        authority_string = "#{authority.hostname}:#{authority.port}"

        conn
        |> put_flash(:error, "The route #{route_string} for the authority #{authority_string} already exists.")
        |> render "new.html", changeset: changeset, authority: authority
    end
    
  end

  def show(conn, %{"authority_id" => authority_id, "id" => id}) do
    case get_authority_and_route(authority_id, id) do
      nil ->
        render conn, "authority_not_found.html"
      {authority, nil} ->
        render conn, "not_found.html", authority: authority
      {authority, route} ->
        render conn, "show.html", route: route, authority: authority
    end
  end

  def edit(conn, %{"authority_id" => authority_id, "id" => id}) do
    case get_authority_and_route(authority_id, id) do
      nil ->
        render conn, "authority_not_found.html"
      {authority, nil} ->
        render conn, "not_found.html", authority: authority
      {authority, route} ->
        changeset = Route.changeset(route)
        render conn, "edit.html", authority: authority, route: route, changeset: changeset
    end
  end

  def update(conn, %{"authority_id" => authority_id, "id" => id, "route" => route_params}) do
    case get_authority_and_route(authority_id, id) do
      nil ->
        render conn, "authority_not_found.html"
      {authority, nil} ->
        render conn, "not_found.html", authority: authority
      {authority, route} ->
        changeset = Route.changeset(route, route_params)

        result = Route
                |> where([r], r.authority_id == ^authority.id and r.id != ^route.id and fragment("lower(?) = lower(?)", r.hostname, ^route_params["hostname"]) and r.port == ^route_params["port"])
                |> Repo.one

        case result do
          nil ->
            if changeset.valid? do
              Repo.update(changeset)

              conn
              |> put_flash(:info, "Route updated successfully.")
              |> redirect(to: web_authority_route_path(conn, :index, authority_id))
            else
              render conn, "edit.html", route: route, changeset: changeset, authority: authority
            end
          _ ->
            route_string = "#{route_params["hostname"]}:#{route_params["port"]}"
            authority_string = "#{authority.hostname}:#{authority.port}"

            conn
            |> put_flash(:error, "The route #{route_string} for the authority #{authority_string} already exists.")
            |> render "edit.html", route: route, changeset: changeset, authority: authority
        end
    end
  end

  def delete(conn, %{"authority_id" => authority_id, "id" => id}) do
    case get_authority_and_route(authority_id, id) do
      nil ->
        render conn, "authority_not_found.html"
      {authority, nil} ->
        render conn, "not_found.html", authority: authority
      {authority, route} ->
        Repo.delete(route)

        conn
        |> put_flash(:info, "Route deleted successfully.")
        |> redirect(to: web_authority_route_path(conn, :index, authority.id))
    end
  end

  @spec get_authority_and_route(integer, integer) :: {Authority.t, nil} | {Authority.t, Route.t} | nil
  defp get_authority_and_route(authority_id, route_id) do
    Authority
    |> where([a], a.id == ^authority_id)
    |> join(:left, [a], r in Route, r.id == ^route_id and r.authority_id == a.id)
    |> select([a, r], {a, r})
    |> Repo.one
  end
end
