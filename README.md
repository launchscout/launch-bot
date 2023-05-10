# LaunchBotServer

This is based off of Chris Nelson's [live_state_comments](https://github.com/launchscout/live_state_comments) repo

## Usage

Typical phoenix:

```
mix deps.get
mix ecto.create
mix ecto.migrate
export OPENAI_API_KEY=<your key>
mix phx.server
```

You can get you OpenAI API key [here](https://platform.openai.com/account/api-keys).

The front end of this app is [here](https://github.com/launchscout/livestate-comments)

You will need to make some changes to this above repo to get it to work with this one.  In the `index.html` file, you will need to change the `url` attribute of the `livestate-comments` tag to point to your server. There is also an issue with the input html tag, which needs to be changed to an text-area tag.