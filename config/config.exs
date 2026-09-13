# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :live, :scopes,
  user: [
    default: true,
    module: Live.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Live.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :live_vue, ssr: true, shared_props: []

config :phoenix_vite, PhoenixVite.Npm,
  assets: [args: [], cd: __DIR__],
  vite: [
    args: ~w(exec -- vite),
    cd: Path.expand("../assets", __DIR__),
    env: %{"MIX_BUILD_PATH" => Mix.Project.build_path()}
  ]

config :live,
  ecto_repos: [Live.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :live, LiveWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: LiveWeb.ErrorHTML, json: LiveWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Live.PubSub,
  live_view: [signing_salt: "KzXkNNC1"]

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :live, Live.Mailer, adapter: Swoosh.Adapters.Local

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :bundlex, :compiler_flags, [
  "-include",
  "cstdint"
]

config :ex_aws,
  json_codec: Jason,
  http_client: ExAws.Request.Req

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 8333,
  access_key_id: "any",
  secret_access_key: "any"

config :finch, :s3_finch, name: ExAws.Finch

config :live,
  storage: :s3,
  s3_bucket: "live-hls",
  s3_prefix: "hls"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
