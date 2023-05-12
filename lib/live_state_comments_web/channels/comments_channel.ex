defmodule LiveStateCommentsWeb.CommentsChannel do
  use LiveState.Channel, web_module: LiveStateCommentsWeb

  alias LiveStateComments.Comments
  alias LiveState.Event

  @impl true
  def state_key, do: :state

  @impl true
  @spec init(any, any, any) :: {:ok, %{comments: any}}
  def init("comments:" <> url, _params, _socket) do
    Phoenix.PubSub.subscribe(LiveStateComments.PubSub, "comments:#{url}")
    {:ok, %{comments: Comments.list_comments(url), url: url}}
  end


  @impl true
  def handle_event("add_comment", comment_params, %{comments: comments} = state) do
    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        case MyApp.OpenAI.chat_with_openai(comments, comment.text) do
          {:ok, response} ->
            {:ok, ai_comment} = Comments.create_comment(%{text: Enum.at(response["choices"], 0)["message"]["content"], author: "assistant", url: comment.url})
            IO.inspect(ai_comment)
            new_state = Map.put(state, :comments, comments ++ [comment, ai_comment])
            {:reply, [%Event{name: "comment_added", detail: comment}, %Event{name: "comment_added", detail: ai_comment}], new_state}

          {:error, _error} ->
            #print the error to the console
            IO.inspect(_error)
            {:reply, [%Event{name: "comment_added", detail: comment}], state}
        end
    end
  end

  @impl true
  def handle_message({:comment_created, _comment}, state) do
    {:noreply, state |> Map.put(:comments, Comments.list_comments(state.url))}
  end


  @impl true
  #mehtod that deletes all comments when a button is clicked
  def handle_event("delete_all_comments", _params, %{comments: comments} = state) do
    comments
    |> Enum.map(fn comment ->
      Comments.delete_comment(comment)
    end)
    {:reply, [%Event{name: "all_comments_deleted"}], Map.put(state, :comments, [])}
  end
end
