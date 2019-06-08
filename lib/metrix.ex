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

  use Statix

  @doc """
  The #{__MODULE__}.start/0 method is used to create a socket connection with the
  configured StatsD server.
  """
  @spec start() :: :ok
  def start do
    :ok = __MODULE__.connect()
  end
end
