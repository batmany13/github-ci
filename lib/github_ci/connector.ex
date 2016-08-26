defmodule GithubCi.Connector do

  def client do
    config = Application.get_env(:github_ci, :github)
    Tentacat.Client.new(%{access_token: config[:access_token]})
  end

  def create_status(data, params) do
    owner = params["organization"]["login"]
    repo = params["base"]["repo"]["name"]
    sha = params["head"]["sha"]
    Tentacat.Repositories.Statuses.create(owner, repo, sha, data, client)
  end

  def heroku(number, params) do
    data = %{"state" => "pending",
            "description" => "waiting for review app",
            "context" => "heroku-review-app"
            }
    create_status(data, params)
  end
end
