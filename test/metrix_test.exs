defmodule MetrixTest do
  use ExUnit.Case, async: true

  describe "start/0" do
    test "starts Metrix by opening a UDP socket" do
      assert Metrix.start() == :ok
    end

    test "sets statix config using metrix config" do
      Application.put_env(:metrix, :host, "localhost")
      Application.put_env(:metrix, :port, 8125)

      assert Metrix.start() == :ok
      assert Application.get_env(:statix, :host) == "localhost"
      assert Application.get_env(:statix, :port) == 8125
    end
  end
end
