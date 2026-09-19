defmodule Live.RTMPServer do
  use Supervisor
  require Logger

  @max_concurrent_pipelines Application.compile_env(
                              :ex_broadcaster,
                              :max_concurrent_pipelines,
                              10
                            )

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    rtmp_port = Application.get_env(:ex_broadcaster, :rtmp_port, 1935)

    children = [
      {Registry, keys: :unique, name: Live.StreamRegistry},
      {Membrane.RTMPServer, port: rtmp_port, handle_new_client: &__MODULE__.handle_new_client/3},
      {DynamicSupervisor, name: __MODULE__.PipelineSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def handle_new_client(client_ref, _app, stream_key) do
    with {:ok, safe_key} <- validate_stream_key(stream_key),
         :ok <- check_capacity() do
      segment_duration_sec = Application.get_env(:ex_broadcaster, :segment_duration_sec, 1)

      name = {:via, Registry, {Live.StreamRegistry, safe_key}}

      pipeline_opts = [
        name: name,
        client_ref: client_ref,
        storage: build_storage(safe_key),
        segment_duration: Membrane.Time.seconds(segment_duration_sec)
      ]

      spec = Supervisor.child_spec({Live.Pipeline, pipeline_opts}, restart: :temporary)

      DynamicSupervisor.start_child(__MODULE__.PipelineSupervisor, spec)

      # DynamicSupervisor.start_child(
      #   __MODULE__.PipelineSupervisor,
      #   Supervisor.child_spec({Live.Pipeline, pipeline_opts, :name, name}, restart: :temporary)
      # )

      Membrane.RTMP.Source.ClientHandlerImpl
    else
      {:error, reason} ->
        Logger.warning(
          "Rejecting RTMP client (stream_key=#{inspect(stream_key)}): #{inspect(reason)}"
        )

        Membrane.RTMP.Source.ClientHandlerImpl
    end
  end

  def is_live?(stream_key) do
    case Registry.lookup(Live.StreamRegistry, stream_key) do
      [{_pid, _val}] -> true
      [] -> false
    end
  end

  defp check_capacity do
    %{active: active} = DynamicSupervisor.count_children(__MODULE__.PipelineSupervisor)

    if active < @max_concurrent_pipelines do
      :ok
    else
      {:error, :capacity_exceeded}
    end
  end

  defp validate_stream_key(stream_key) when is_binary(stream_key) do
    safe_key =
      stream_key
      |> Path.basename()
      |> String.replace(~r/[^a-zA-Z0-9_\-]/, "")

    cond do
      safe_key == "" -> {:error, :empty_stream_key}
      String.length(safe_key) > 128 -> {:error, :stream_key_too_long}
      true -> {:ok, safe_key}
    end
  end

  defp validate_stream_key(_), do: {:error, :invalid_stream_key}

  defp build_storage(stream_key) do
    case Application.get_env(:live, :storage, :file) do
      :s3 ->
        bucket = Application.fetch_env!(:live, :s3_bucket)
        prefix = Application.get_env(:live, :s3_prefix, "hls")

        %Live.Storages.S3Storage{
          bucket: bucket,
          prefix: Enum.join([prefix, date_path(), stream_key], "/")
        }

      :file ->
        base_dir = Application.get_env(:ex_broadcaster, :hls_output_dir, "output/hls")
        output_dir = Path.join(base_dir, stream_key)
        File.mkdir_p!(output_dir)
        %Membrane.HTTPAdaptiveStream.Storages.FileStorage{directory: output_dir}
    end
  end

  defp date_path do
    %{year: y, month: m, day: d, hour: h} = DateTime.utc_now()
    "#{y}/#{pad2(m)}/#{pad2(d)}/#{pad2(h)}"
  end

  defp pad2(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")
end
