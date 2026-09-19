defmodule LiveWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use LiveWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_scope, :map, default: nil, doc: "the current scope"

  slot :inner_block, required: true

  def app(assigns) do
    # Подготавливаем список пользователей для Vue
    recommended_users =
      Live.Accounts.list_recommended_users()
      |> Enum.map(fn user ->
        %{
          id: user.id,
          username: user.username,
          avatar_url: user.avatar_url,
          category: Map.get(user, :category, "Just Chatting"),
          viewers_count: Map.get(user, :viewers_count, Enum.random(15..450)),
          is_live: Map.get(user, :is_live, true)
        }
      end)

    assigns = assign(assigns, :recommended_users, recommended_users)

    ~H"""
    <div class="min-h-screen bg-base-100 text-base-content flex flex-col">
      <!-- Top Navbar -->
      <header class="navbar bg-base-200/80 backdrop-blur-md border-b border-base-300 sticky top-0 z-30 px-4 gap-4">
        <!-- Brand Logo -->
        <div class="flex-none">
          <.link navigate={~p"/"} class="flex items-center gap-2 font-bold text-xl tracking-wide text-primary">
            <.logo />
          </.link>
        </div>

        <!-- Navigation Links -->
        <ul class="menu menu-horizontal px-1 hidden md:flex font-medium text-sm gap-1">
          <li><.link navigate={~p"/"} class="rounded-xl">Browse</.link></li>
          <li><.link navigate={~p"/categories"} class="rounded-xl">Categories</.link></li>
        </ul>

        <!-- Search Bar -->
        <div class="flex-1 max-w-md mx-auto hidden sm:block">
          <div class="relative w-full">
            <span class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-base-content/40">
              <.icon name="hero-magnifying-glass" class="size-4" />
            </span>
            <input
              type="text"
              placeholder="Search channels or games..."
              class="input input-sm w-full pl-9 pr-4 bg-base-300/60 focus:bg-base-100 border-base-300 focus:border-primary transition-all rounded-xl text-sm"
            />
          </div>
        </div>

        <!-- Right Action Items -->
        <div class="flex-none flex items-center gap-2 ml-auto">
          <.link navigate={~p"/dashboard"} class="btn btn-primary btn-sm gap-2 rounded-xl">
            <.icon name="hero-video-camera" class="size-4" />
            <span class="hidden sm:inline">Go Live</span>
          </.link>

          <.theme_toggle />

          <!-- User Menu -->
          <%= if @current_scope do %>
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar border border-base-300">
                <div class="w-8 rounded-full">
                  <img src={"https://api.dicebear.com/7.x/bottts/svg?seed=#{@current_scope.user.email}"} alt="Avatar" />
                </div>
              </div>
              <ul tabindex="0" class="mt-3 z-[50] p-2 shadow-2xl menu menu-sm dropdown-content bg-base-200 rounded-2xl w-56 border border-base-300">
                <li class="px-3 py-2 border-b border-base-300/60">
                  <span class="text-xs text-base-content/60 font-mono truncate">
                    {@current_scope.user.email}
                  </span>
                </li>
                <li><.link href={~p"/users/settings"}>Settings</.link></li>
                <li><.link navigate={~p"/dashboard"}>Stream Dashboard</.link></li>
                <div class="divider my-1"></div>
                <li>
                  <.link href={~p"/users/log-out"} method="delete" class="text-error font-semibold">
                    Log out
                  </.link>
                </li>
              </ul>
            </div>
          <% else %>
            <div class="flex items-center gap-1.5">
              <.link href={~p"/users/log-in"} class="btn btn-ghost btn-sm rounded-xl">Log in</.link>
              <.link href={~p"/users/register"} class="btn btn-primary btn-sm rounded-xl">Register</.link>
            </div>
          <% end %>
        </div>
      </header>

      <!-- Main Layout Structure -->
      <div class="flex flex-1 overflow-hidden">
        <!-- LiveVue Interactive Sidebar -->
        <.Sidebar channels={@recommended_users} />

        <!-- Main Content Area -->
        <main class="flex-1 overflow-y-auto p-4 lg:p-6 w-full max-w-[1920px] mx-auto">
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def auth(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 flex flex-col justify-center items-center p-4 relative">
      <div class="absolute top-4 right-4">
        <.theme_toggle />
      </div>

      <div class="w-full max-w-md space-y-6">
        <div class="text-center space-y-2">
          <.link navigate={~p"/"} class="inline-flex items-center gap-2">
            <.logo />
          </.link>
        </div>

        <div class="bg-base-200 p-8 rounded-3xl border border-base-300 shadow-xl">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    assigns =
      assign(assigns, :themes, [
        %{id: "system", name: "System", icon: "hero-computer-desktop-micro"},
        %{id: "dark", name: "Dark", icon: "hero-moon-micro"},
        %{id: "night", name: "Night", icon: "hero-sparkles-micro"},
        %{id: "dracula", name: "Dracula", icon: "hero-eye-micro"},
        %{id: "sunset", name: "Sunset", icon: "hero-fire-micro"},
        %{id: "light", name: "Light", icon: "hero-sun-micro"}
      ])

    ~H"""
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-sm gap-2 border border-base-300 rounded-xl">
        <.icon name="hero-swatch-micro" class="size-4" />
        <span class="hidden sm:inline text-xs font-medium">Theme</span>
        <.icon name="hero-chevron-down-micro" class="size-3 opacity-60" />
      </div>

      <ul
        tabindex="0"
        class="dropdown-content z-[50] menu p-2 shadow-2xl bg-base-200 rounded-2xl w-52 mt-2 border border-base-300 gap-1"
      >
        <li :for={theme <- @themes}>
          <button
            type="button"
            class="flex items-center justify-between py-2 text-xs rounded-xl"
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme={theme.id}
          >
            <div class="flex items-center gap-2">
              <.icon name={theme.icon} class="size-4 opacity-70" />
              <span>{theme.name}</span>
            </div>
            <span
              class="flex gap-0.5 p-1 bg-base-100 rounded border border-base-300"
              data-theme={theme.id}
            >
              <span class="size-2 rounded-full bg-primary inline-block"></span>
              <span class="size-2 rounded-full bg-secondary inline-block"></span>
              <span class="size-2 rounded-full bg-accent inline-block"></span>
            </span>
          </button>
        </li>
      </ul>
    </div>
    """
  end
end
