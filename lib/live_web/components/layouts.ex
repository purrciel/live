defmodule LiveWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use LiveWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open min-h-screen bg-base-100 text-base-content">
      <input id="main-drawer" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col">
        <!-- Top Navbar -->
        <header class="navbar bg-base-200 border-b border-base-300 sticky top-0 z-30 px-4 gap-4">
          <!-- Mobile Sidebar Toggle -->
          <div class="flex-none lg:hidden">
            <label for="main-drawer" aria-label="open sidebar" class="btn btn-square btn-ghost">
              <.icon name="hero-bars-3" class="size-6" />
            </label>
          </div>

          <!-- Brand Logo -->
          <div class="flex-none">
            <a href="/" class="flex items-center gap-2 font-bold text-xl tracking-wide text-primary">
              <.logo />
            </a>
          </div>

          <!-- Navigation Links -->
          <ul class="menu menu-horizontal px-1 hidden md:flex font-medium">
            <li><a href="/" class="active">Browse</a></li>
            <li><a href="/categories">Categories</a></li>
          </ul>

          <!-- Search Bar -->
          <div class="flex-1 max-w-md mx-auto hidden sm:block">
            <div class="form-control w-full">
              <div class="input-group flex items-center bg-base-300 rounded-lg px-3">
                <.icon name="hero-magnifying-glass" class="size-5 text-base-content/50 mr-2" />
                <input
                  type="text"
                  placeholder="Search channels or games..."
                  class="input input-sm border-none bg-transparent focus:outline-none w-full"
                />
              </div>
            </div>
          </div>

          <!-- Right Action Items -->
          <div class="flex-none flex items-center gap-3 ml-auto">
            <a href="/dashboard" class="btn btn-primary btn-sm gap-2">
              <.icon name="hero-video-camera" class="size-4" />
              <span class="hidden sm:inline">Go Live</span>
            </a>

            <.theme_toggle />

            <!-- User Menu / Auth Links -->
            <%= if @current_scope do %>
              <div class="dropdown dropdown-end">
                <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                  <div class="w-9 rounded-full ring ring-primary ring-offset-base-100 ring-offset-2">
                    <img
                      src={"https://api.dicebear.com/7.x/bottts/svg?seed=#{@current_scope.user.email}"}
                      alt="Avatar"
                    />
                  </div>
                </div>
                <ul
                  tabindex="0"
                  class="mt-3 z-[50] p-2 shadow-lg menu menu-sm dropdown-content bg-base-200 rounded-box w-56 space-y-1 border border-base-300"
                >
                  <li class="px-3 py-2 border-b border-base-300">
                    <span class="text-xs text-base-content/60 font-mono truncate">
                      {@current_scope.user.email}
                    </span>
                  </li>
                  <li><.link href={~p"/users/settings"}>Settings</.link></li>
                  <li><a href="/dashboard">Stream Dashboard</a></li>
                  <div class="divider my-1"></div>
                  <li>
                    <.link href={~p"/users/log-out"} method="delete" class="text-error">
                      Log out
                    </.link>
                  </li>
                </ul>
              </div>
            <% else %>
              <div class="flex items-center gap-2">
                <.link href={~p"/users/log-in"} class="btn btn-ghost btn-sm">
                  Log in
                </.link>
                <.link href={~p"/users/register"} class="btn btn-primary btn-sm">
                  Register
                </.link>
              </div>
            <% end %>
          </div>
        </header>

        <!-- Main Content Area -->
        <main class="flex-1 p-4 lg:p-6 w-full max-w-[1920px] mx-auto">
          {render_slot(@inner_block)}
        </main>
      </div>
      <!-- Left Sidebar (Recommended Channels) -->
      <div class="drawer-side z-40">
        <label for="main-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
        <aside class="bg-base-200 w-64 min-h-full border-r border-base-300 flex flex-col p-3">
          <div class="px-3 py-2 text-xs font-semibold uppercase tracking-wider text-base-content/60 flex items-center justify-between">
            <span>Recommended Channels</span>
            <.icon name="hero-signal" class="size-4 text-error animate-pulse" />
          </div>

          <!-- Dynamic Channel List -->
          <ul class="menu menu-md w-full space-y-1 p-0 mt-2">
            <%= for user <- Live.Accounts.list_recommended_users() do %>
              <li>
                <.link navigate={~p"/c/#{user.username}"} class="flex items-center gap-3 py-2">
                  <div class="avatar online">
                    <div class="w-8 rounded-full">
                      <img
                        src={
                          user.avatar_url ||
                            "https://api.dicebear.com/7.x/bottts/svg?seed=#{user.username}"
                        }
                        alt={user.username}
                      />
                    </div>
                  </div>
                  <div class="flex-1 overflow-hidden">
                    <p class="font-semibold text-sm truncate">{user.username}</p>
                    <p class="text-xs text-base-content/60 truncate">
                      {user.category || "Just Chatting"}
                    </p>
                  </div>
                  <div class="text-xs font-mono text-base-content/70 flex items-center gap-1">
                    <span class="size-2 rounded-full bg-error inline-block"></span> LIVE
                  </div>
                </.link>
              </li>
            <% end %>
          </ul>
        </aside>
      </div>
    </div>
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders clean layout for authentication pages (Login, Register, Password Reset).
  No sidebar, centered card container.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def auth(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 flex flex-col justify-center items-center p-4 relative">
      <!-- Theme Toggle in top-right corner -->
      <div class="absolute top-4 right-4">
        <.theme_toggle />
      </div>

      <!-- Main Auth Wrapper -->
      <div class="w-full max-w-md space-y-6">
        <!-- Logo Header -->
        <div class="text-center space-y-2">
          <a
            href="/"
            class="inline-flex items-center gap-2 font-bold text-3xl tracking-wide text-primary"
          >
            <.logo />
          </a>
        </div>

        <!-- Auth Card Body -->
        <div class="bg-base-200 p-8 rounded-3xl border border-base-300 shadow-xl">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
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

  @doc """
  Renders a theme selector dropdown with standard and custom DaisyUI themes.
  """
  def theme_toggle(assigns) do
    assigns =
      assign(assigns, :themes, [
        %{id: "system", name: "System", icon: "hero-computer-desktop-micro"},
        %{id: "sunset", name: "Sunset", icon: "hero-fire-micro"},
        %{id: "dark", name: "Dark (Default)", icon: "hero-moon-micro"},
        %{id: "night", name: "Night (Twitch)", icon: "hero-sparkles-micro"},
        %{id: "dracula", name: "Dracula", icon: "hero-eye-micro"},
        %{id: "light", name: "Light", icon: "hero-sun-micro"}
      ])

    ~H"""
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-sm gap-2 border border-base-300">
        <.icon name="hero-swatch-micro" class="size-4" />
        <span class="hidden sm:inline text-xs font-medium">Theme</span>
        <.icon name="hero-chevron-down-micro" class="size-3 opacity-60" />
      </div>

      <ul
        tabindex="0"
        class="dropdown-content z-[50] menu p-2 shadow-2xl bg-base-200 rounded-box w-52 mt-2 border border-base-300 gap-1"
      >
        <li :for={theme <- @themes}>
          <button
            type="button"
            class="flex items-center justify-between py-2 text-xs"
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme={theme.id}
          >
            <div class="flex items-center gap-2">
              <.icon name={theme.icon} class="size-4 opacity-70" />
              <span>{theme.name}</span>
            </div>
            <!-- Индикатор цвета темы из DaisyUI -->
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
