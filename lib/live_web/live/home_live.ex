defmodule LiveWeb.HomeLive do
  use LiveWeb, :live_view

  alias Live.Accounts
  alias Live.RTMPServer

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
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

        <div class="space-y-4">
          <div class="flex items-center justify-between">
            <h2 class="text-2xl font-bold tracking-tight flex items-center gap-2">
              <.icon name="hero-signal" class="size-6 text-error animate-pulse" /> Live Channels
            </h2>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
            <%= for channel <- @channels do %>
              <.vue
                v-component="StreamCard"
                v-socket={@socket}
                channel={
                  %{
                    username: channel.username,
                    avatar_url: channel.avatar_url,
                    stream_title: channel.stream_title || "No title",
                    category: channel.category || "Just Chatting",
                    is_live: channel.is_live,
                    stream_url: channel.stream_url
                  }
                }
              />
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

      stream_url = if is_live, do: get_hls_stream_url(user.stream_key), else: nil

      user
      |> Map.put(:is_live, is_live)
      |> Map.put(:stream_url, stream_url)
    end)
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
