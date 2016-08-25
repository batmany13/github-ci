defmodule GithubCi.Router do
  use GithubCi.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GithubCi do
    pipe_through :api

    post "/event_handler", EventHandlerController, :create
    get "/status", EventHandlerController, :status
  end
end
