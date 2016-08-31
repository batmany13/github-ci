## GithubCi

This is a simple Elixir/Phoenix application that will act as a simple CI server as described by this [article](https://developer.github.com/guides/building-a-ci-server/).  This server will interact with the GitHub status [api](https://developer.github.com/v3/repos/statuses/)

## Setup

__Configure your GitHub credentials__

```
export ACCESS_TOKEN=<github token>
```

Configure a personal access token [here](https://github.com/settings/tokens)

__Setup config data__

Set the environment variable ```CI_CONFIG``` or Create a ```ci_config.json``` file in the root directory

Config File Format

```javascript
{
 "ws1" : {
   "deployment" :"heroku", 
   "tests" : [["runscope", "<my url>"]],
 "ws2" : {
   "deployment" : "heroku",
   "tests" : [["ghostinspector", "<my url>"]]
 }
}
```

Refer to the sample config [file](ci_config_sample.json) for the example

## Usage

This supports waiting for a few items

* Deployment App on Heroku
* Runscope - trigger a runscope test and wait for it to complete

## To be implemented

* Ghost Inspector - trigger a ghost inspector test and wait for it to complete

## Running on Heroku

You will need to create an Elixir application that can run on Heroku.

https://github.com/techgaun/heroku-buildpack-elixir.git    
https://github.com/techgaun/heroku-buildpack-mix-tasks.git    

```ACCESS_TOKEN=<github token>```   
```HEROKU_API_KEY=<heroku api key>```    
```SECRET_KEY_BASE=<secret key for Phoenix>```    
```RUNSCOPE_TOKEN=<runscope token>```    
```CI_CONFIG=<URI encoded ci_config.json file>```    

Generate the ci_config.json file

```
iex -S mix
"ci_config.json" |> File.read! |> URI.encode
```

## Misc

It is highly recommended to use [ngrok](https://ngrok.com/) for local development work and testing.
