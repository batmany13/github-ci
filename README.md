## GithubCi

This is a simple Elixir/Phoenix application that will act as a "dummy" CI server as described by this [article](https://developer.github.com/guides/building-a-ci-server/).  This server will interact with the GitHub status [api](https://developer.github.com/v3/repos/statuses/)

## Usage

This supports waiting for a few items

* Heroku Review App - wait for a review app to be launched
* Runscope - trigger a runscope test and wait for it to complete
* Ghost Inspector - trigger a ghost inspector test and wait for it to complete

## Misc

It is highly recommended to use [ngrok](https://ngrok.com/) for local development work and testing.