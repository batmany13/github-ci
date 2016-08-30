defmodule GithubCi.Parser do
  @moduledoc """
  A parser to parse responses
  """

  @type status_code :: integer
  @type response :: {:ok, [struct]} | {:ok, struct} | :ok | {:error, map, status_code} | {:error, map} | any

  @spec parse(tuple) :: GithubCi.response
  def parse(response) do
    case response do
      {:ok, %HTTPoison.Response{body: body, headers: _, status_code: status}} when status in [200, 201] ->
        {:ok, body |> Poison.decode!}

      {:ok, %HTTPoison.Response{body: _, headers: _, status_code: 204}} ->
        :ok

      {:ok, %HTTPoison.Response{body: body, headers: _, status_code: 404}} ->
        {:ok, %{"error" => error}} = body |> Poison.decode
        {:error, %{reason: error}}

      {:ok, %HTTPoison.Response{body: body, headers: _, status_code: status}} ->
        {:ok, json} = Poison.decode(body)
        {:error, json["error"]["message"], status}

      {:error, %HTTPoison.Error{id: _, reason: reason}} ->
        {:error, %{reason: reason}}
      _ ->
        response
    end
  end
end