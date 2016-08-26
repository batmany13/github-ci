defmodule GithubCi.EventHandlerController do
  use GithubCi.Web, :controller

  def status(conn, params) do
    render(conn, "status.json")
  end

  def create(conn, params) do
    headers = conn.req_headers |> Enum.into(%{})
    case headers do
      %{"x-github-event" => "pull_request"} -> render(conn, "status.json", details: process_pr(params["pull_request"]))
      %{"x-github-event" => event} -> render(conn, "status.json", event: event)
      _ -> render(conn, "status.json")
    end
  end

  def process_pr(%{"state" => "open", "number" => number} = params) do
    GithubCi.Connector.heroku(number, params)
  end
  def process_pr(params), do: params
end
