defmodule Metrix do
  @moduledoc """
  Metrix is a library for collecting StatsD metrics. It is built on top of [`statix`](https://github.com/lexmag/statix). By using Statix, the following functions
  are injected into this module:

  * decrement/1,2,3
  * gauge/2,3
  * histogram/2,3
  * increment/1,2,3
  * measure/2,3
  * set/2,3
  * timing/2,3
  """

  use Statix, runtime_config: true

  @config_options [:prefix, :host, :port, :tags]

  @doc """
  The #{__MODULE__}.start/0 method is used to create a socket connection with the
  configured StatsD server.
  """
  @spec start() :: :ok
  def start do
    :ok = set_config()
    :ok = __MODULE__.connect()
  end

  @spec set_config() :: :ok
  defp set_config do
    Enum.each(@config_options, &set_statix_config/1)
  end

  @spec set_statix_config(atom) :: :ok
  defp set_statix_config(option) do
    if metrix_value = Application.get_env(:metrix, option) do
      Application.put_env(:statix, option, metrix_value)
    end
  end
end
