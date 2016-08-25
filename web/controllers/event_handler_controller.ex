defmodule GithubCi.EventHandlerController do
  use GithubCi.Web, :controller

  def status(conn, params) do
    render(conn, "status.json")
  end

  def create(conn, params) do
    headers = conn.req_headers |> Enum.into(%{})
    case headers do
      %{"x-github-event" => "pull_request"} ->
       pr_params = params["pull_request"]
       render(conn, "status.json", pr: pr_params)
      %{"x-github-event" => event} ->
       render(conn, "status.json", event: event)
    end
  end
end
