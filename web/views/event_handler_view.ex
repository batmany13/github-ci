defmodule GithubCi.EventHandlerView do
  use GithubCi.Web, :view

  def render("status.json", %{details: params}) do
    %{"status" => "ok", "details" => Poison.encode!(params)}
  end

  def render("status.json", %{event: event}) do
    %{"status" => "ok", "details" => "received '#{event}' event from GitHub"}
  end
end
