defmodule ExMetrics.Plug do
  @moduledoc """
  The ExMetrics.Plug module provides a plug for capturing response times and sending
  those metrics to a StatsD server.
  """
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, options) do
    metric_name = get_metric_name(conn)

    start_time = System.monotonic_time()

    register_before_send(conn, fn conn ->
      end_time = System.monotonic_time()
      time_ms = (end_time - start_time) / 1_000

      if Keyword.get(options, :histogram) do
        ExMetrics.histogram(metric_name, time_ms)
      else
        ExMetrics.timing(metric_name, time_ms)
      end

      conn
    end)
  end

  @spec get_metric_name(Plug.Conn.t()) :: String.t()
  defp get_metric_name(conn) do
    "response_time#{metric_name_from_request_path(conn.request_path)}"
  end

  @spec metric_name_from_request_path(String.t()) :: String.t()
  defp metric_name_from_request_path("/"), do: ".root"

  defp metric_name_from_request_path(request_path) do
    request_path
    |> String.replace("/", ".")
    |> String.replace(~r/\.+/, ".")
    |> String.trim_trailing(".")
    |> String.replace(":", "")
  end
end
