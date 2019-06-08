defmodule MetrixTest do
  use ExUnit.Case, async: true

  describe "start/0" do
    test "starts Metrix by opening a UDP socket" do
      assert Metrix.start() == :ok
    end
  end
end
