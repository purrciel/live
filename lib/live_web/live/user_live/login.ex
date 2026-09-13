defmodule LiveWeb.UserLive.Login do
  use LiveWeb, :live_view

  alias Live.Accounts
  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.auth flash={@flash}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center space-y-2">
          <h1 class="text-2xl font-bold">Log in to OxygenLive</h1>

          <p :if={@current_scope} class="text-xs text-warning bg-warning/10 p-2 rounded-lg">
            You need to reauthenticate to perform sensitive actions on your account.
          </p>

          <p class="text-sm text-base-content/70">
            Don't have an account?
            <.link
              navigate={~p"/users/register"}
              class="font-semibold text-primary hover:underline ml-1"
            >
              Sign up
            </.link>
          </p>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info py-2 text-xs">
          <.icon name="hero-information-circle" class="size-5 shrink-0" />
          <div>
            <p>Running local mail adapter.</p>
            <p>
              Check sent emails at <.link href="/dev/mailbox" class="underline">/dev/mailbox</.link>.
            </p>
          </div>
        </div>

        <!-- Magic Link Form -->
        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full mt-2">
            Log in with email <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="divider text-xs text-base-content/50">OR PASSWORD</div>

        <!-- Password Form -->
        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
            spellcheck="false"
          />

          <div class="space-y-2 mt-4">
            <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
              Log in and stay logged in
            </.button>
            <.button type="submit" class="btn btn-ghost btn-sm w-full">
              Log in only this time
            </.button>
          </div>
        </.form>

        <!-- Footer link back home / register fallback -->
        <div class="text-center pt-4 border-t border-base-300">
          <.link navigate={~p"/"} class="text-xs text-base-content/60 hover:text-primary">
            ← Back to Home
          </.link>
        </div>
      </div>
    </Layouts.auth>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:live, Live.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
