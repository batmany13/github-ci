defmodule GithubCi.Runscope do
  alias GithubCi.Parser
  
  def test_exec(env, %{"id" => id} = status, url, params) do
    HTTPoison.start
    IO.puts "found successful status #{id} for #{env}"
    app = "https://#{env}.herokuapp.com"
    url = "#{url}&url=#{app}"
    IO.puts "executing test '#{url}'"
    resp = url
    |> HTTPoison.get
    |> Parser.parse
    |> parse_status
  end

  def parse_status({:ok, %{"error" => error}}) when not is_nil(error), do: {:error, error}
  def parse_status({:ok, %{"data" => %{"runs" => [run | _rest]}}}), do: {:ok, run}
  def parse_status({:ok, %{"data" => %{"result" => "pass", "assertions_failed" => 0, "assertions_passed" => succeeded, "assertions_defined" => total}}} = status) do 
    {:ok, "successfullly ran #{succeeded}/#{total} assertions"}
  end
  def parse_status({:ok, %{"data" => %{"result" => "fail", "assertions_failed" => failed, "assertions_passed" => succeeded, "assertions_defined" => total}}}) do
    {:error, "runscope test failure, #{failed}/#{total} assertions failed"}
  end
  def parse_status({:error, %{"reason" => msg}}), do: {:error, msg}
  def parse_status(params), do: {:wait, "waiting for test execution to finish"}
  
  def status(%{"bucket_key" => bucket_key, "test_id" => test_id, "test_run_id" => test_run_id}) do
    HTTPoison.start
    ret = "https://api.runscope.com/buckets/#{bucket_key}/tests/#{test_id}/results/#{test_run_id}"
    |> HTTPoison.get(auth_header)
    |> Parser.parse
    |> parse_status
  end

  def status do
    bucket_key = "to5q0u5gglr4"
    test_id = "685aa69d-c7eb-4f39-8060-cd0922b47bc2"
    test_run_id = "d8b8d307-3576-44f7-b086-c97c73ad63ec"
    HTTPoison.start
    ret = "https://api.runscope.com/buckets/#{bucket_key}/tests/#{test_id}/results/#{test_run_id}"
    |> HTTPoison.get(auth_header)
    |> Parser.parse
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