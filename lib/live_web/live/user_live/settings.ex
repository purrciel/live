defmodule LiveWeb.UserLive.Settings do
  use LiveWeb, :live_view

  on_mount {LiveWeb.UserAuth, :require_sudo_mode}

  alias Live.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto space-y-8">
        <div>
          <.header>
            Account & Channel Settings
            <:subtitle>Manage your streaming profile, email, and password</:subtitle>
          </.header>
        </div>

        <!-- Section 1: Channel Profile Settings -->
        <div class="card bg-base-200 border border-base-300 shadow-sm p-6 space-y-4">
          <h2 class="text-lg font-bold flex items-center gap-2">
            <.icon name="hero-tv" class="size-5 text-primary" /> Channel Profile
          </h2>

          <.form
            for={@profile_form}
            id="profile_form"
            phx-submit="update_profile"
            phx-change="validate_profile"
            class="space-y-4"
          >
            <.input
              field={@profile_form[:username]}
              type="text"
              label="Username / Channel Handle"
              placeholder="e.g. streamer_pro"
              required
            />

            <.input
              field={@profile_form[:stream_title]}
              type="text"
              label="Stream Title"
              placeholder="My awesome livestream"
              required
            />

            <.input
              field={@profile_form[:category]}
              type="select"
              label="Category"
              options={[
                "Just Chatting": "Just Chatting",
                Gaming: "Gaming",
                "Software & Tech": "Software & Tech",
                Music: "Music"
              ]}
            />

            <.input
              field={@profile_form[:bio]}
              type="textarea"
              label="Bio / About You"
              placeholder="Tell viewers about your channel..."
              rows="3"
            />

            <div class="pt-2">
              <.button variant="primary" phx-disable-with="Saving profile...">
                Save Profile
              </.button>
            </div>
          </.form>
        </div>

        <!-- Section 2: Email Change -->
        <div class="card bg-base-200 border border-base-300 shadow-sm p-6 space-y-4">
          <h2 class="text-lg font-bold flex items-center gap-2">
            <.icon name="hero-envelope" class="size-5 text-primary" /> Email Settings
          </h2>

          <.form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
            class="space-y-4"
          >
            <.input
              field={@email_form[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              spellcheck="false"
              required
            />
            <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
          </.form>
        </div>

        <!-- Section 3: Password Change -->
        <div class="card bg-base-200 border border-base-300 shadow-sm p-6 space-y-4">
          <h2 class="text-lg font-bold flex items-center gap-2">
            <.icon name="hero-key" class="size-5 text-primary" /> Password Settings
          </h2>

          <.form
            for={@password_form}
            id="password_form"
            action={~p"/users/update-password"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
            class="space-y-4"
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              spellcheck="false"
              value={@current_email}
            />
            <.input
              field={@password_form[:password]}
              type="password"
              label="New password"
              autocomplete="new-password"
              spellcheck="false"
              required
            />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              autocomplete="new-password"
              spellcheck="false"
            />
            <.button variant="primary" phx-disable-with="Saving...">
              Save Password
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    profile_changeset = Accounts.change_user_profile(user)
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_profile", %{"user" => profile_params}, socket) do
    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(profile_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", %{"user" => profile_params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_profile(user, profile_params) do
      {:ok, updated_user} ->
        scope = %{socket.assigns.current_scope | user: updated_user}

        {:noreply,
         socket
         |> assign(:current_scope, scope)
         |> assign(:profile_form, to_form(Accounts.change_user_profile(updated_user)))
         |> put_flash(:info, "Channel profile updated successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
