defmodule LiveWeb.HlsController do
  use LiveWeb, :controller

  # Filer API (порт 8888) или S3 API (порт 8333) SeaweedFS
  @s3_public_url "http://localhost:8888/buckets/live-hls/hls"

  def stream(conn, %{"path" => path_segments}) do
    s3_path = Enum.join(path_segments, "/")
    target_url = "#{@s3_public_url}/#{s3_path}"

    case Req.get(target_url) do
      {:ok, %Req.Response{status: 200, body: body, headers: headers}} ->
        content_type = get_content_type(s3_path, headers)

        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("access-control-allow-origin", "*")
        |> send_resp(200, body)

      {:ok, %Req.Response{status: 404}} ->
        send_resp(conn, 404, "Segment not found")

      {:error, _reason} ->
        send_resp(conn, 502, "Storage gateway error")
    end
  end

  defp get_content_type(path, headers) do
    cond do
      String.ends_with?(path, ".m3u8") ->
        "application/vnd.apple.mpegurl"

      String.ends_with?(path, ".m4s") ->
        "video/iso.segment"

      String.ends_with?(path, ".mp4") ->
        "video/mp4"

      true ->
        case List.keyfind(headers, "content-type", 0) do
          {_, [val | _]} -> val
          {_, val} when is_binary(val) -> val
          _ -> "application/octet-stream"
        end
    end
  end
end
