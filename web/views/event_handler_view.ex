defmodule GithubCi.EventHandlerView do
  use GithubCi.Web, :view

  def render("status.json", %{pr: params}) do
    %{"status" => "ok", "params" => Poison.encode!(params)}
  end

  def render("status.json", %{event: event}) do
    %{"status" => "ok", "details" => "received '#{event}' event from GitHub"}
  end
end
