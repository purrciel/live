defmodule Live.Storages.S3Storage do
  @behaviour Membrane.HTTPAdaptiveStream.Storage
  require Logger

  @enforce_keys [:bucket, :prefix]
  defstruct @enforce_keys

  @impl true
  def init(%__MODULE__{} = config), do: config

  @impl true
  def store(_parent_id, name, content, _metadata, _ctx, %{bucket: bucket, prefix: prefix} = state) do
    key = prefix <> "/" <> name

    case bucket |> ExAws.S3.put_object(key, content) |> ExAws.request() do
      {:ok, _} -> {:ok, state}
      {:error, reason} ->
        Logger.error("S3 upload failed for #{key}: #{inspect(reason)}")
        {{:error, reason}, state}
    end
  end

  @impl true
  def remove(_parent_id, name, _ctx, %{bucket: bucket, prefix: prefix} = state) do
    key = prefix <> "/" <> name

    case bucket |> ExAws.S3.delete_object(key) |> ExAws.request() do
      {:ok, _} -> {:ok, state}
      {:error, reason} ->
        Logger.warning("S3 delete failed for #{key}: #{inspect(reason)}")
        {{:error, reason}, state}
    end
  end
end
