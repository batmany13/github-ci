defmodule GithubCi.Runscope do
  alias GithubCi.Parser
  
  def test_exec(env, %{"id" => id} = status, url, params) do
    HTTPoison.start
    IO.puts "found successful status #{id} for #{env}"
    app = "https://#{env}.herokuapp.com"
    resp = "#{url}?url=#{app}"
    |> HTTPoison.get
    |> Parser.parse
    |> parse_status
  end

  def handle(_, _, _, _), do: {:error, "unknown status format"}

  def parse_status({:ok, %{"error" => error}}) when not is_nil(error), do: {:error, error}
  def parse_status({:ok, %{"meta" => %{"status" => "success"}, "data" => %{"runs" => [run | _rest]}}}), do: {:ok, run}
  def parse_status({:ok, %{"meta" => %{"status" => "success"}, "data" => %{"assertions_defined" => total}}} = status) when total == 0, do: {:wait, "no tests have ran yet"}
  def parse_status({:ok, %{"meta" => %{"status" => "success"}, "data" => %{"assertions_failed" => 0, "assertions_passed" => succeeded, "assertions_defined" => total}}} = status) do
    {:ok, "successfullly ran #{succeeded}/#{total} tests"}
  end
  def parse_status({:ok, %{"meta" => %{"status" => "success"}, "data" => %{"assertions_failed" => failed, "assertions_passed" => succeeded, "assertions_defined" => total}}}) when failed > 0 do
    {:error, "runscope test failure, #{failed}/#{total} tests"}
  end
  def parse_status({:error, %{"reason" => msg}}), do: {:error, msg}
  def parse_status(params), do: IO.inspect params ; {:wait, "waiting for test execution to finish"}
  
  def status(%{"bucket_key" => bucket_key, "test_id" => test_id, "test_run_id" => test_run_id}) do
    HTTPoison.start
    ret = "https://api.runscope.com/buckets/#{bucket_key}/tests/#{test_id}/results/#{test_run_id}"
    |> HTTPoison.get(auth_header)
    |> Parser.parse
    |> parse_status
  end

  def auth_header do
    token = System.get_env("RUNSCOPE_TOKEN")
    if is_nil(token) do
      raise "Runscope token is missing"
    else
      [{"Authorization", "Bearer #{token}"}]
    end
  end
end