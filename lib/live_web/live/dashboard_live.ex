defmodule LiveWeb.DashboardLive do
  use LiveWeb, :live_view

  alias Live.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    is_live = Live.RTMPServer.is_live?(user.stream_key)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Live.PubSub, "stream:#{user.id}")
    end

    socket =
      socket
      |> assign(:page_title, "Stream Dashboard")
      |> assign(:show_key, false)
      |> assign(:is_live, is_live)
      |> assign(:rtmp_url, "rtmp://localhost:1935/live")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6 max-w-7xl mx-auto">
        <!-- Dashboard Header -->
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-base-200 p-6 rounded-2xl border border-base-300">
          <div>
            <h1 class="text-2xl font-bold flex items-center gap-3">
              <.icon name="hero-video-camera" class="size-8 text-primary" />
              Stream Dashboard
            </h1>
            <p class="text-sm text-base-content/60 mt-1">
              Manage your stream settings and broadcast configuration
            </p>
          </div>

          <!-- Status Indicator -->
          <div class="flex items-center gap-3">
            <span class="text-sm font-medium">Status:</span>
            <%= if @is_live do %>
              <div class="badge badge-error gap-2 p-3 font-semibold text-white animate-pulse">
                <span class="size-2 rounded-full bg-white inline-block"></span>
                LIVE NOW
              </div>
            <% else %>
              <div class="badge badge-ghost gap-2 p-3 text-base-content/60">
                <span class="size-2 rounded-full bg-base-content/30 inline-block"></span>
                OFFLINE
              </div>
            <% end %>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Left Main Column: Stream Preview & Live Chat/Stats Placeholder -->
          <div class="lg:col-span-2 space-y-6">
            <!-- Stream Preview Box -->
            <div class="card bg-base-200 border border-base-300 overflow-hidden shadow-sm">
              <div class="card-body p-4">
                <h2 class="card-title text-base flex items-center justify-between">
                  <span>Stream Preview</span>
                  <span class="text-xs font-mono font-normal opacity-60">
                    HLS Path: /hls/{@current_scope.user.stream_key}/index.m3u8
                  </span>
                </h2>

                <div class="aspect-video bg-black rounded-xl relative flex items-center justify-center overflow-hidden border border-base-300">
                  <%= if @is_live do %>
                    <.vue
                      v-component="VideoPlayer"
                      v-socket={@socket}
                      streamUrl={get_hls_stream_url(@current_scope.user.stream_key)}
                      autoplay={true}
                      class="w-full h-full"
                    />
                  <% else %>
                    <div class="text-center p-6 text-base-content/50">
                      <.icon name="hero-signal-slash" class="size-12 mx-auto mb-2 opacity-40" />
                      <p class="font-semibold text-base">Stream is offline</p>
                      <p class="text-xs mt-1">Start sending RTMP stream from OBS to show preview</p>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <!-- Quick Stats -->
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-4">
              <div class="stat bg-base-200 rounded-xl border border-base-300 p-4">
                <div class="stat-title text-xs">Current Viewers</div>
                <div class="stat-value text-2xl text-primary mt-1">0</div>
              </div>
              <div class="stat bg-base-200 rounded-xl border border-base-300 p-4">
                <div class="stat-title text-xs">Bitrate</div>
                <div class="stat-value text-2xl text-secondary mt-1">
                  {if @is_live, do: "6,000 Kbps", else: "0 Kbps"}
                </div>
              </div>
              <div class="stat bg-base-200 rounded-xl border border-base-300 p-4 col-span-2 sm:col-span-1">
                <div class="stat-title text-xs">Uptime</div>
                <div class="stat-value text-2xl mt-1">00:00:00</div>
              </div>
            </div>
          </div>

          <!-- Right Column: OBS Settings / Keys -->
          <div class="space-y-6">
            <div class="card bg-base-200 border border-base-300 shadow-sm">
              <div class="card-body p-5 space-y-4">
                <h2 class="card-title text-lg flex items-center gap-2">
                  <.icon name="hero-key" class="size-5 text-primary" />
                  Stream Credentials
                </h2>
                <p class="text-xs text-base-content/70">
                  Copy these credentials into OBS Studio / Streamlabs under Settings -> Stream -> Custom...
                </p>

                <!-- RTMP URL -->
                <div class="form-control w-full">
                  <label class="label py-1">
                    <span class="label-text text-xs font-semibold">Server URL</span>
                  </label>
                  <div class="flex gap-2">
                    <input
                      type="text"
                      readonly
                      value={@rtmp_url}
                      class="input input-sm input-bordered font-mono text-xs w-full bg-base-300"
                    />
                    <button
                      type="button"
                      class="btn btn-sm btn-square btn-ghost border border-base-300"
                      phx-click={JS.dispatch("phx:copy", to: "#rtmp-url-val")}
                      id="rtmp-url-val"
                      data-value={@rtmp_url}
                    >
                      <.icon name="hero-clipboard-document" class="size-4" />
                    </button>
                  </div>
                </div>

                <!-- Stream Key -->
                <div class="form-control w-full">
                  <label class="label py-1">
                    <span class="label-text text-xs font-semibold">Stream Key</span>
                  </label>
                  <div class="flex gap-2">
                    <input
                      type={if @show_key, do: "text", else: "password"}
                      readonly
                      value={@current_scope.user.stream_key}
                      class="input input-sm input-bordered font-mono text-xs w-full bg-base-300"
                    />
                    <button
                      type="button"
                      class="btn btn-sm btn-square btn-ghost border border-base-300"
                      phx-click="toggle_key_visibility"
                    >
                      <.icon
                        name={if @show_key, do: "hero-eye-slash", else: "hero-eye"}
                        class="size-4"
                      />
                    </button>
                  </div>
                </div>

                <!-- Actions -->
                <div class="pt-2 flex flex-col gap-2">
                  <button
                    type="button"
                    class="btn btn-outline btn-error btn-sm w-full gap-2"
                    phx-click="reset_stream_key"
                    data-confirm="Are you sure? Your current stream will fail if you are live!"
                  >
                    <.icon name="hero-arrow-path" class="size-4" />
                    Reset Stream Key
                  </button>
                </div>
              </div>
            </div>

            <!-- OBS Instructions Box -->
            <div class="alert bg-base-200 border border-base-300 text-xs space-y-1 block">
              <p class="font-bold text-primary flex items-center gap-1">
                <.icon name="hero-information-circle" class="size-4" /> OBS Setup Guide
              </p>
              <ol class="list-decimal list-inside space-y-1 text-base-content/80 pt-1">
                <li>Service: <strong>Custom...</strong></li>
                <li>Server: <code>rtmp://localhost:1935/live</code></li>
                <li>Stream Key: Paste your key from above</li>
                <li>Output: H.264 Video, AAC Audio</li>
              </ol>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("toggle_key_visibility", _params, socket) do
    {:noreply, assign(socket, :show_key, !socket.assigns.show_key)}
  end

  def handle_event("reset_stream_key", _params, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.reset_user_stream_key(user) do
      {:ok, updated_user} ->
        scope = %{socket.assigns.current_scope | user: updated_user}

        {:noreply,
         socket
         |> assign(:current_scope, scope)
         |> put_flash(:info, "New Stream Key generated successfully!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not reset stream key.")}
    end
  end


  @impl true
  def handle_info({:stream_status, status}, socket) do
    {:noreply, assign(socket, :is_live, status == :online)}
  end

  def handle_info({:stream_started, _stream_key}, socket) do
    {:noreply, assign(socket, :is_live, true)}
  end

  def handle_info({:stream_stopped, _stream_key}, socket) do
    {:noreply, assign(socket, :is_live, false)}
  end

  defp check_if_live(stream_key) do
    base_dir = Application.get_env(:ex_broadcaster, :hls_output_dir, "output/hls")
    manifest_path = Path.join([base_dir, stream_key, "index.m3u8"])
    File.exists?(manifest_path)
  end

  defp get_hls_stream_url(stream_key) do
    # Формируем путь с текущей датой/часом в UTC (или берём активный из БД/Redis)
    now = DateTime.utc_now()
    year = String.pad_leading("#{now.year}", 4, "0")
    month = String.pad_leading("#{now.month}", 2, "0")
    day = String.pad_leading("#{now.day}", 2, "0")
    hour = String.pad_leading("#{now.hour}", 2, "0")

    "/hls/#{year}/#{month}/#{day}/#{hour}/#{stream_key}/index.m3u8"
  end
end
