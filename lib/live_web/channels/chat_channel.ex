defmodule LiveWeb.ChatChannel do
  use LiveWeb, :channel

  @impl true
  def join("chat:" <> stream_key, _payload, socket) do
    # Можем проверить существует ли такой stream_key
    case Live.Accounts.get_user_by_stream_key(stream_key) do
      %Live.Accounts.User{} = streamer ->
        {:ok, assign(socket, :streamer_id, streamer.id)}

      nil ->
        {:error, %{reason: "Channel not found"}}
    end
  end

  @impl true
  def handle_in("new_msg", %{"text" => text, "username" => username}, socket) do
    msg = %{
      id: Ecto.UUID.generate(),
      username: username,
      text: text,
      at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    # Рассылаем всем подключенным зрителям чата
    broadcast!(socket, "new_msg", msg)
    {:noreply, socket}
  end
end
