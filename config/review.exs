use Mix.Config

config :github_ci, GithubCi.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  url: [host: "https://#{System.get_env("HEROKU_APP_NAME")}.herokuapp.com", port: 80],
  code_reloader: true,
  http: [port: {:system, "PORT"}],
  cache_static_manifest: "priv/static/manifest.json"

# Do not print debug messages in production
config :logger, level: :info