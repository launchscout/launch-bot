defmodule MyApp.OpenAI do
  require HTTPoison

  @api_url "https://api.openai.com/v1/chat/completions"
  @api_key System.get_env("OPENAI_API_KEY")

  def chat_with_openai(state, message) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{@api_key}"}
    ]

    body = Poison.encode!(%{
      "model" => "gpt-3.5-turbo",
      "messages" => transform_state(state, message),
    })

    case HTTPoison.post(@api_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Poison.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: Poison.decode!(body)}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{reason: reason}}
    end
  end

  def transform_state(state, current_string) do
    state
    |> Enum.map(fn comment ->
      %{
        "role" => (comment.author == "assistant" && "assistant") || "user",
        "content" => comment.text
      }
    end)
    |> List.insert_at(-1, %{"role" => "user", "content" => current_string})
  end
end
