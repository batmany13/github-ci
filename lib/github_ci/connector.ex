defmodule GithubCi.Connector do

  def client do
    config = Application.get_env(:github_ci, :github)
    Tentacat.Client.new(%{access_token: config[:access_token]})
  end

  def create_status(data, params) do
    {owner, repo, sha} = parse_params(params)
    Tentacat.Repositories.Statuses.create(owner, repo, sha, data, client)
  end

  def status(params) do
    {owner, repo, sha} = parse_params(params)
    statuses = Tentacat.Repositories.Statuses.find(owner, repo, sha, client)
    IO.inspect statuses
    statuses
  end

  def deployments(params) do
    {owner, repo, sha} = parse_params(params)
    Tentacat.Repositories.Deployments.list(owner, repo, client)
  end

  def deployment(params) do
    {_owner, _repo, sha} = parse_params(params)
    dep = params
    |> deployments
    |> Enum.find(fn(dep) -> dep["sha"] == sha end)
    {dep, deployment_status(dep["id"], params)}
  end

  def deployment_status(id, params) do
    {owner, repo, sha} = parse_params(params)
    Tentacat.Repositories.Deployments.list_statuses(owner, repo, id, client)
  end

  def build_data(context, statuses) when length(statuses) == 0, do: %{"state" => "failure", "context" => context, "description" => "failed as no valid statuses were found"}
  def build_data(context, statuses) do
    status = Enum.at(statuses, 0)
    {state, desc} = case status do
      %{"state" => "success"} -> {"success", "completed successfully"}
      %{"state" => state, "description" => desc} -> {state, desc}
    end
    %{"state" => state,
      "context" => context,
      "description" => desc
    }
  end

  def wait_for_status(context, params) do
    {dep, status} = deployment(params)
    send self(), parse_status(status)
    receive do
      {:ok, found} ->
        # once we found it, set the heroku status
        data = build_data(context, found)
        {status, msg} = create_status(data, params)
        IO.puts "create status return #{status}"
    after
      5_000 -> wait_for_status(context, params)
    end
  end

  def parse_status({404, %{"message" => msg}}), do: {:error, msg}
  def parse_status(statuses) do 
    found = Enum.filter(statuses, fn(status) -> Enum.any?(valid_status, &(&1 == status["state"])) end) 
    if length(found) > 0, do: {:ok, found}, else: {:error, "no valid status found"}
  end

  def valid_status, do: ["success", "inactive", "failure"]

  def parse_params(params) do
    owner = params["head"]["user"]["login"]
    repo = params["base"]["repo"]["name"]
    sha = params["head"]["sha"]
    #owner = "Brightergy"
    #repo = "github-ci"
    #sha = "5bd94f27a37e6f17fbb5599a137203d7e1762ff9"
    {owner, repo, sha}
  end

  def heroku(number, params) do
    context = "heroku-review-app"
    data = %{"state" => "pending",
            "description" => "waiting for review app",
            "context" => context
            }
    
    case create_status(data, params) do
      {201, msg} ->
       {:ok, pid} = Task.start(fn -> wait_for_status(context, params) end)
       "Opened PR #{number}, created status, started wait_for_status process"
      {status, %{"message" => msg}} -> "For PR #{number}, failed to create status #{status} #{msg}"
    end
  end
end
