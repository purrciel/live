defmodule LiveWeb.ChannelLive do
  use LiveWeb, :live_view

  alias Live.Accounts

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    case Accounts.get_user_by_username(username) do
      %Accounts.User{} = streamer ->
        is_live = Live.RTMPServer.is_live?(streamer.stream_key)

        if connected?(socket) do
          Phoenix.PubSub.subscribe(Live.PubSub, "stream:#{streamer.id}")
          Phoenix.PubSub.subscribe(Live.PubSub, "chat:#{streamer.stream_key}")
        end

        socket =
          socket
          |> assign(:page_title, "#{streamer.username}'s Stream")
          |> assign(:streamer, streamer)
          |> assign(:is_live, is_live)
          |> assign(:messages, [])

        {:ok, socket}

      nil ->
        {:ok, socket |> put_flash(:error, "Channel not found") |> redirect(to: "/")}
    end
  end

  @impl true
  def handle_event("send_chat_message", %{"text" => text, "username" => username}, socket) do
    msg = %{
      id: Ecto.UUID.generate(),
      username: username,
      text: text,
      at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Phoenix.PubSub.broadcast(
      Live.PubSub,
      "chat:#{socket.assigns.streamer.stream_key}",
      {:new_chat_msg, msg}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_chat_msg, msg}, socket) do
    {:noreply, update(socket, :messages, fn msgs -> msgs ++ [msg] end)}
  end

  @impl true
  def handle_info({:stream_status, status}, socket) do
    {:noreply, assign(socket, :is_live, status == :online)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto space-y-6">
        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 h-[calc(100vh-12rem)]">
          <div class="lg:col-span-3 flex flex-col space-y-4 overflow-y-auto">
            <div class="aspect-video bg-black rounded-2xl overflow-hidden border border-base-300 shadow-md">
              <%= if @is_live do %>
                <.vue
                  v-component="VideoPlayer"
                  v-socket={@socket}
                  streamUrl={get_hls_stream_url(@streamer.stream_key)}
                  autoplay={true}
                  class="w-full h-full"
                />
              <% else %>
                <div class="w-full h-full flex flex-col items-center justify-center text-base-content/50 p-6">
                  <.icon name="hero-video-camera-slash" class="size-16 mb-3 opacity-40" />
                  <h3 class="text-xl font-bold">{@streamer.username} is Offline</h3>
                  <p class="text-sm mt-1">Check back later for live broadcasts!</p>
                </div>
              <% end %>
            </div>

            <div class="bg-base-200 p-5 rounded-2xl border border-base-300 flex items-start justify-between gap-4">
              <div class="flex items-center gap-4">
                <div class="avatar placeholder">
                  <div class="bg-neutral text-neutral-content rounded-full size-14">
                    <span class="text-xl font-bold">
                      {String.at(@streamer.username, 0) |> String.upcase()}
                    </span>
                  </div>
                </div>

                <div>
                  <h1 class="text-xl font-bold flex items-center gap-2">
                    {@streamer.username}
                    <%= if @is_live do %>
                      <span class="badge badge-error text-white font-semibold text-xs">LIVE</span>
                    <% end %>
                  </h1>
                  <p class="text-sm text-base-content/70 mt-0.5">{@streamer.stream_title}</p>
                  <div class="flex items-center gap-2 mt-2">
                    <span class="badge badge-outline text-xs">{@streamer.category}</span>
                  </div>
                </div>
              </div>

              <button class="btn btn-primary btn-sm gap-2">
                <.icon name="hero-heart" class="size-4" /> Follow
              </button>
            </div>
          </div>

          <div class="lg:col-span-1 h-full min-h-[400px]">
            <.vue
              v-component="StreamChat"
              v-socket={@socket}
              messages={@messages}
              currentUser={
                if @current_scope.user && @current_scope.user.username,
                  do: @current_scope.user.username,
                  else: "User_#{:rand.uniform(999)}"
              }
              class="h-full"
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp get_hls_stream_url(stream_key) do
    now = DateTime.utc_now()
    year = String.pad_leading("#{now.year}", 4, "0")
    month = String.pad_leading("#{now.month}", 2, "0")
    day = String.pad_leading("#{now.day}", 2, "0")
    hour = String.pad_leading("#{now.hour}", 2, "0")

    "/hls/#{year}/#{month}/#{day}/#{hour}/#{stream_key}/index.m3u8"
  end
end
