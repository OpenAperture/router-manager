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

    resources "/authorities", AuthorityController do
      resources "/routes", RouteController
    end
  end

  scope "/api", RouterManager, as: :api do
    pipe_through :api

    resources "/authorities", Api.AuthorityController do
      resources "/routes", Api.RouteController
    end

    get "/routes", Api.RoutesController, :index
  end
end
