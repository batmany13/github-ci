defmodule GithubCi.Connector do
  alias GithubCi.Runscope

  @sample_info {"Brightergy", "github-ci", "f3bf50557c6d90d963d3a18ca18e6c9793f00c81"}

  def config, do: config(System.get_env("CI_CONFIG"))
  def config(nil), do: "ci_config.json" |> File.read! |> Poison.decode!
  def config(data), do: data |> URI.decode |> Poison.decode!
  def config("encode"), do: "ci_config.json" |> File.read! |> URI.encode

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
    Tentacat.Repositories.Statuses.find(owner, repo, sha, client)
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

  def wait_for_status("heroku", context, params, pids) do
    {dep, status} = deployment(params)
    IO.puts "got status for deployment #{dep["id"]}"
    send self(), {dep, parse_status(status)}
    receive do
      {dep, {:ok, found}} ->
        # once we found it, set the heroku status
        data = build_data(context, found)
        {status, msg} = create_status(data, params)
        Enum.map(pids, fn(pid) -> send(pid, {dep, found}) end)
    after
      5_000 -> wait_for_status("heroku", context, params, pids)
    end
  end

  # This will ignore errors in a wait for status since there's a Runscope bug where
  # calling the test_result on a specific test_run_id returns 404
  def wait_for_status("runscope", context, params, run, 0) do
    status = Runscope.status(run)
    send self(), status
    IO.puts "wait for runscope status on run 0"
    receive do
      {:ok, desc} ->
        IO.puts desc
        %{"state" => "success", "description" => desc, "context" => context}
        |> create_status(params)
    after
      3_000 -> wait_for_status("runscope", context, params, run, 1)
    end
  end

  def wait_for_status("runscope", context, params, run, ct) do
    status = Runscope.status(run)
    IO.puts "in wait for Runscope status, ct #{ct}"
    send self(), status
    receive do
      {:ok, desc} ->
        IO.puts desc
        %{"state" => "success", "description" => desc, "context" => context}
        |> create_status(params)
      {:error, error} ->
        %{"state" => "failure", "description" => error, "context" => context}
        |> create_status(params)
    after
      5_000 -> wait_for_status("runscope", context, params, run, ct + 1)
    end
  end


  def parse_status({404, %{"message" => msg}}), do: {:error, msg}
  def parse_status(statuses) do 
    found = Enum.filter(statuses, fn(status) -> Enum.any?(valid_status, &(&1 == status["state"])) end) 
    if length(found) > 0, do: {:ok, found}, else: {:error, "no valid status found"}
  end

  def valid_status, do: ["success", "inactive", "failure"]

  def parse_params(%{}), do: @sample_info
  def parse_params(params) do
    owner = params["head"]["user"]["login"]
    repo = params["base"]["repo"]["name"]
    sha = params["head"]["sha"]
    {owner, repo, sha}
  end

  def fire, do: fire(%{})

  def fire(params) do
    IO.inspect params
    {_, repo, _} = parse_params(params)
    case Map.fetch(config, repo) do
      {:ok, data} ->
        {:ok, tests} = Map.fetch(data, "tests")
        case handle("deployment", data, params) do
          {:ok, pid} ->
            number = params["number"]
            "Opened PR #{number}, created status, started wait_for_status process"
          {:error, msg} ->
            "Failed to send status properly : #{msg}"
        end
      :error ->
        "Missing config for '#{repo}', skipping"
    end
    #"For PR #{number}, failed to create status #{status} #{msg}"
  end

  def handle(key, data, params) do
    case Map.fetch(data, key) do
      {:ok, value} ->
        handle(key, value, data, params)
      _ ->
        IO.puts "no value for #{key}, skipping"
    end
  end

  def handle("deployment", "heroku", config_data, params) do
    {_, repo, sha} = parse_params(params)
    IO.puts "handling heroku deployment for '#{repo}', '#{sha}'"
    context = "deployment-to-heroku"
    data = %{"state" => "pending",
            "description" => "waiting for deployment to finish",
            "context" => context
            }
    case create_status(data, params) do
      {201, msg} ->
        pids = process_tests(config_data, params)
        IO.puts "kicking off wait task"
       {:ok, pid} = Task.start(fn -> wait_for_status("heroku", context, params, pids) end)
      {status, %{"message" => msg}} -> 
        IO.puts "errored"
        {:error, msg}
    end
  end
  def handle(type, _, _, _), do: "missing config for '#{type}', skipping"

  def process_tests(%{"tests" => tests}, params) do
    tests
    |> Enum.with_index
    |> Enum.map(fn({[type, url], idx}) -> 
      IO.puts "processing #{type}"
      context = "#{type}-test-#{idx}"
      data = %{"state" => "pending",
              "description" => "waiting for test to run",
              "context" => context
              }
      case create_status(data, params) do
        {201, msg} ->
         {:ok, pid} = Task.start(fn -> test_runner(type, url, context, params) end)
         pid
        {status, %{"message" => msg}} -> 
          IO.puts "errored"
          nil
       end
    end)
    |> Enum.reject(fn(x) -> is_nil(x) end)
  end
  def process_tests(_, _), do: IO.puts "no valid tests to run" ; []

  def test_runner("runscope", url, context, params) do
    receive do
      {dep, found} ->
        env = dep["environment"]
        status = Enum.find(found, &(&1["state"] == "success"))
        case Runscope.test_exec(env, status, url, params) do
          {:ok, run} -> 
           IO.puts "successfully executed test, wait for test completion"
           {:ok, pid} = Task.start(fn -> wait_for_status("runscope", context, params, run, 0) end)
          {:error, msg} -> IO.puts "error with execution : #{msg}"
        end
    after
      5_000 -> test_runner("runscope", url, context, params)
    end    
  end
  def test_runner(_, _), do: IO.puts "no tests to run"

end
