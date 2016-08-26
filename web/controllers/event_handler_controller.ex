defmodule GithubCi.EventHandlerController do
  use GithubCi.Web, :controller

  def status(conn, params) do
    render(conn, "status.json")
  end

  def create(conn, params) do
    headers = conn.req_headers |> Enum.into(%{})
    case headers do
      %{"x-github-event" => "pull_request"} ->
       render(conn, "status.json", details: process_pr(params["pull_request"]))
      %{"x-github-event" => event} ->
       render(conn, "status.json", event: event)
    end
  end

  def process_pr(%{"state" => "open", "number" => number} = params) do
    config = Application.get_env(:github_ci, :github)
    IO.inspect config
    client = Tentacat.Client.new(%{access_token: config[:access_token]})
    data = %{"state" => "pending",
            "description" => "waiting for heroku to bring up the server",
            "context" => "heroku review app"
            }
    owner = params["organization"]["login"]
    repo = params["base"]["repo"]["name"]
    sha = params["head"]["sha"]
    ret = Tentacat.Repositories.Statuses.create(owner, repo, sha, data, client)
    "opened PR #{number}, updating status, return : #{ret}"
  end
  def process_pr(params), do: params
end
