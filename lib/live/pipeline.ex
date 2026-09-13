defmodule Live.Pipeline do
  use Membrane.Pipeline
  require Membrane.Logger, as: Logger

  alias Membrane.HTTPAdaptiveStream

  # Пады hls_sink, EOS от которых мы должны получить перед завершением
  @expected_pads MapSet.new([
                   Pad.ref(:input, {:video, :source}),
                   Pad.ref(:input, {:audio, :source})
                 ])

  def start_link(opts) do
      process_opts = Keyword.take(opts, [:name])
      Membrane.Pipeline.start_link(__MODULE__, opts, process_opts)
  end

  @impl true
  def handle_init(_ctx, opts) do
    client_ref = Keyword.fetch!(opts, :client_ref)
    storage = Keyword.fetch!(opts, :storage)
    segment_duration = Keyword.get(opts, :segment_duration, Membrane.Time.seconds(1))

    spec = [
      child(:rtmp_source, %Membrane.RTMP.SourceBin{client_ref: client_ref}),
      child(:hls_sink, %HTTPAdaptiveStream.Sink{
        manifest_config: %HTTPAdaptiveStream.Sink.ManifestConfig{
          name: "index",
          module: HTTPAdaptiveStream.HLS
        },
        track_config: %HTTPAdaptiveStream.Sink.TrackConfig{
          mode: :live,
          target_window_duration: Membrane.Time.seconds(6)
        },
        storage: storage
      }),

      # ВИДЕО ПОТОК: RTMP -> Parser -> CMAF Muxer -> HLS Sink
      get_child(:rtmp_source)
      |> via_out(:video)
      |> child(:h264_parser, %Membrane.H264.Parser{
        output_alignment: :au,
        output_stream_structure: :avc1
      })
      |> child(:video_muxer, %Membrane.MP4.Muxer.CMAF{
        segment_min_duration: segment_duration
      })
      |> via_in(Pad.ref(:input, {:video, :source}), options: [segment_duration: segment_duration])
      |> get_child(:hls_sink),

      # АУДИО ПОТОК: RTMP -> Parser -> CMAF Muxer -> HLS Sink
      get_child(:rtmp_source)
      |> via_out(:audio)
      |> child(:aac_parser, %Membrane.AAC.Parser{
        out_encapsulation: :none,
        output_config: :esds
      })
      |> child(:audio_muxer, %Membrane.MP4.Muxer.CMAF{
        segment_min_duration: segment_duration
      })
      |> via_in(Pad.ref(:input, {:audio, :source}), options: [segment_duration: segment_duration])
      |> get_child(:hls_sink)
    ]

    {[spec: spec], %{ended_pads: MapSet.new()}}
  end

  @impl true
  def handle_element_end_of_stream(:hls_sink, pad, _ctx, state) do
    ended = MapSet.put(state.ended_pads, pad)

    Logger.info(
      "HLS sink pad #{inspect(pad)} finished (#{MapSet.size(ended)}/#{MapSet.size(@expected_pads)})"
    )

    if MapSet.subset?(@expected_pads, ended) do
      Logger.info("All HLS sink pads finished. Terminating pipeline.")
      {[terminate: :normal], %{state | ended_pads: ended}}
    else
      {[], %{state | ended_pads: ended}}
    end
  end

  def handle_element_end_of_stream(_child, _pad, _ctx, state), do: {[], state}
end
