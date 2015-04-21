defmodule RouterManager.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RouterManager, as: :web do
    pipe_through :browser # Use the default browser stack

    get "/", AuthorityController, :index

    resources "/authorities", AuthorityController
    resources "/authorities/:parent_id/routes", RouteController
  end

  scope "/api", RouterManager, as: :api do
    pipe_through :api

    resources "/authorities", Api.AuthorityController

    delete "/authorities/:parent_id/routes/clear", Api.RouteController, :clear
    resources "/authorities/:parent_id/routes", Api.RouteController

    get "/routes", Api.RoutesController, :index
  end
end
