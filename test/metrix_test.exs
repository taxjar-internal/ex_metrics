defmodule ExMetricsTest do
  use ExUnit.Case, async: true

  describe "start/0" do
    test "starts ExMetrics by opening a UDP socket" do
      assert ExMetrics.start() == :ok
    end

    test "sets statix config using ex_metrics config" do
      Application.put_env(:ex_metrics, :host, "localhost")
      Application.put_env(:ex_metrics, :port, 8125)

      assert ExMetrics.start() == :ok
      assert Application.get_env(:statix, :host) == "localhost"
      assert Application.get_env(:statix, :port) == 8125
    end
  end
end
