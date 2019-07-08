defmodule ExMetrics.PlugTest do
  use ExUnit.Case, async: false
  use Plug.Test
  import Mimic

  defmodule MetricsAgent do
    use Agent

    def start_link() do
      Agent.start_link(fn -> nil end, name: __MODULE__)
    end

    def get() do
      Agent.get(__MODULE__, fn state -> state end)
    end

    def set(values) do
      Agent.update(__MODULE__, fn _ -> values end)
    end
  end

  describe "init/1" do
    test "returns options unchanged" do
      assert ExMetrics.Plug.init(key: :value) == [key: :value]
    end
  end

  describe "call/2" do
    setup _context do
      MetricsAgent.start_link()

      stub(ExMetrics, :timing, fn name, value ->
        MetricsAgent.set({:timing, name, value})
      end)

      stub(ExMetrics, :histogram, fn name, value ->
        MetricsAgent.set({:histogram, name, value})
      end)

      :ok
    end

    test "collects response time metrics for a request" do
      conn = conn(:get, "/v1/users/:id")

      result_conn =
        conn
        |> ExMetrics.Plug.call([])
        |> Plug.Conn.send_resp(200, "")

      {:timing, name, time} = MetricsAgent.get()

      assert result_conn.status == 200
      assert result_conn.state == :sent
      assert name == "response_time.v1.users.id"
      assert is_float(time)
    end

    test "can be configured to use histogram instead of timing" do
      conn = conn(:get, "/v2/accounts/:id/edit")

      result_conn =
        conn
        |> ExMetrics.Plug.call(histogram: true)
        |> Plug.Conn.send_resp(200, "")

      {:histogram, name, time} = MetricsAgent.get()

      assert result_conn.status == 200
      assert result_conn.state == :sent
      assert name == "response_time.v2.accounts.id.edit"
      assert is_float(time)
    end

    test "properly handles root request path" do
      conn = conn(:get, "/")

      result_conn =
        conn
        |> ExMetrics.Plug.call([])
        |> Plug.Conn.send_resp(200, "")

      {:timing, name, time} = MetricsAgent.get()

      assert result_conn.status == 200
      assert result_conn.state == :sent
      assert name == "response_time.root"
      assert is_float(time)
    end

    test "strips multiple consecutive periods" do
      conn = conn(:get, "/v2/users/?id=1234")

      result_conn =
        conn
        |> ExMetrics.Plug.call([])
        |> Plug.Conn.send_resp(200, "")

      {:timing, name, time} = MetricsAgent.get()

      assert result_conn.status == 200
      assert result_conn.state == :sent
      assert name == "response_time.v2.users"
      assert is_float(time)
    end
  end
end
