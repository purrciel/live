defmodule LiveWeb.HomeLive do
  use LiveWeb, :live_view

  alias Live.Accounts
  alias Live.RTMPServer

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Подписываемся на глобальные события стримов (если RTMPServer их рассилает)
      Phoenix.PubSub.subscribe(Live.PubSub, "streams")
    end

    channels = fetch_channels()

    socket =
      socket
      |> assign(:page_title, "Browse Streams")
      |> assign(:channels, channels)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <!-- Hero Banner / Featured Stream Section -->
        <div class="relative rounded-3xl bg-gradient-to-r from-primary/20 via-base-200 to-base-300 p-8 border border-base-300 overflow-hidden shadow-lg">
          <div class="max-w-2xl relative z-10 space-y-4">
            <span class="badge badge-primary font-semibold text-xs tracking-wider uppercase">
              Welcome to OxygenLive
            </span>
            <h1 class="text-4xl font-extrabold tracking-tight sm:text-5xl">
              Watch, Stream, Connect.
            </h1>
            <div class="flex items-center gap-3 pt-2">
              <%= if @current_scope do %>
                <.link href="/dashboard" class="btn btn-primary gap-2">
                  <.icon name="hero-video-camera" class="size-5" /> Go to Dashboard
                </.link>
              <% else %>
                <.link href={~p"/users/register"} class="btn btn-primary gap-2">
                  Start Streaming Now
                </.link>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Live Channels Section -->
        <div class="space-y-4">
          <div class="flex items-center justify-between">
            <h2 class="text-2xl font-bold tracking-tight flex items-center gap-2">
              <.icon name="hero-signal" class="size-6 text-error animate-pulse" /> Live Channels
            </h2>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
            <%= for channel <- @channels do %>
              <.link
                navigate={~p"/c/#{channel.username}"}
                class="group bg-base-200 rounded-2xl overflow-hidden border border-base-300 hover:border-primary transition-all duration-200 hover:shadow-xl flex flex-col"
              >
                <!-- Thumbnail Preview -->
                <div class="aspect-video bg-base-300 relative overflow-hidden flex items-center justify-center">
                  <%= if channel.is_live do %>
                    <span class="absolute top-3 left-3 badge badge-error text-white font-semibold text-xs z-10">
                      LIVE
                    </span>
                    <.icon
                      name="hero-play-circle"
                      class="size-12 text-primary opacity-80 group-hover:scale-110 transition-transform"
                    />
                  <% else %>
                    <span class="absolute top-3 left-3 badge badge-neutral text-xs z-10">
                      OFFLINE
                    </span>
                    <.icon name="hero-video-camera-slash" class="size-10 text-base-content/30" />
                  <% end %>
                </div>

                <!-- Info Header -->
                <div class="p-4 flex gap-3">
                  <div class="avatar flex-none">
                    <div class="w-10 h-10 rounded-full ring-2 ring-primary/20 group-hover:ring-primary transition-all">
                      <img
                        src={
                          channel.avatar_url ||
                            "https://api.dicebear.com/7.x/bottts/svg?seed=#{channel.username}"
                        }
                        alt={channel.username}
                      />
                    </div>
                  </div>

                  <div class="flex-1 min-w-0">
                    <h3 class="font-bold text-base truncate group-hover:text-primary transition-colors">
                      {channel.username}
                    </h3>
                    <p class="text-xs text-base-content/70 truncate">
                      {channel.stream_title || "No stream title"}
                    </p>
                    <div class="mt-2">
                      <span class="badge badge-sm badge-outline text-[10px]">
                        {channel.category || "Just Chatting"}
                      </span>
                    </div>
                  </div>
                </div>
              </.link>
            <% end %>
          </div>

          <%= if Enum.empty?(@channels) do %>
            <div class="text-center py-16 bg-base-200/50 rounded-2xl border border-dashed border-base-300">
              <.icon name="hero-tv" class="size-12 mx-auto text-base-content/30 mb-3" />
              <h3 class="text-lg font-bold">No channels registered yet</h3>
              <p class="text-sm text-base-content/60 mt-1">
                Create an account to become the first streamer!
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp fetch_channels do
    Accounts.list_recommended_users()
    |> Enum.map(fn user ->
      is_live = user.stream_key != nil && RTMPServer.is_live?(user.stream_key)
      Map.put(user, :is_live, is_live)
    end)
  end
end
