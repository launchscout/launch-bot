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

    options = [recv_timeout: 30_000]

    case HTTPoison.post(@api_url, body, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: res}} ->
        case Poison.decode(res) do
          {:ok, decoded} ->
            {:ok, decoded}
          {:error, reason} ->
            {:error, %{reason: "Failed to decode response: #{reason}"}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: res}} ->
        case Poison.decode(res) do
          {:ok, decoded} ->
            {:error, %{status_code: status_code, body: decoded}}
          {:error, reason} ->
            {:error, %{reason: "Failed to decode error response: #{reason}"}}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{reason: reason}}

      _ ->
        {:error, %{reason: "Unexpected error"}}
    end
  end

  def transform_state(state, current_string) do
    state
    |> Enum.map(fn comment ->
      %{
        "role" => determine_role(comment.author),
        "content" => comment.text
      }
    end)
    |> List.insert_at(-1, %{"role" => "user", "content" => current_string})
  end

  def determine_role(author) do
    if author == "assistant" do
      "assistant"
    else
      "user"
    end
  end
end
