defmodule GithubCi.Router do
  use GithubCi.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/handler", GithubCi do
    pipe_through :api
  end
end
