defmodule ExMetrics.FunctionTimerTest do
  use ExUnit.Case, async: false
  import Mimic

  @default_prefix "function_call.elixir.exmetrics.functiontimertest.timedmodule"

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

  defmodule TimedModule do
    use ExMetrics.FunctionTimer

    deftimed(default, do: :default)

    @metric_name "custom_metric"
    deftimed(custom_metric_name, do: :custom_metric_name)

    deftimed(no_custom_metric_name, do: :no_custom_metric_name)

    @metric_name "multiple"
    deftimed(multiple(:option_1), do: :multiple_1)
    deftimed(multiple(:option_2), do: :multiple_2)

    @metric_name "multiple_default"
    deftimed(multiple(_), do: :multiple_default)

    @metric_options [tags: [:custom_options_tag]]
    deftimed(custom_metric_options, do: :custom_metric_options)

    deftimed(no_custom_metric_options, do: :no_custom_metric_options)

    @metric_options [tags: [:multiple_options_tag]]
    deftimed(multiple_options(:option_1), do: :multiple_options_1)
    deftimed(multiple_options(:option_2), do: :multiple_options_2)

    @metric_options [tags: [:multiple_options_default_tag]]
    deftimed(multiple_options(_), do: :multiple_options_default)
  end

  describe "deftimed/2" do
    setup :set_mimic_global

    setup _context do
      MetricsAgent.start_link()

      stub(ExMetrics, :timing, fn name, value, options ->
        MetricsAgent.set({name, value, options})
      end)

      stub(ExMetrics, :histogram, fn name, value, options ->
        MetricsAgent.set({name, value, options})
      end)

      :ok
    end

    test "default metric name and options" do
      result = TimedModule.default()
      {metric_name, time, []} = MetricsAgent.get()

      assert result == :default
      assert metric_name == "#{@default_prefix}.default_0"
      assert is_float(time)
    end

    test "custom metric name" do
      result = TimedModule.custom_metric_name()
      {metric_name, time, []} = MetricsAgent.get()

      assert result == :custom_metric_name
      assert metric_name == "custom_metric"
      assert is_float(time)
    end

    test "custom metric name does not apply to next function in file" do
      result = TimedModule.no_custom_metric_name()
      {metric_name, time, []} = MetricsAgent.get()

      assert result == :no_custom_metric_name
      assert metric_name == "#{@default_prefix}.no_custom_metric_name_0"
      assert is_float(time)
    end

    test "custom metric name applies to multiple function headers" do
      result1 = TimedModule.multiple(:option_1)
      {metric_name1, time1, []} = MetricsAgent.get()

      result2 = TimedModule.multiple(:option_2)
      {metric_name2, time2, []} = MetricsAgent.get()

      assert result1 == :multiple_1
      assert metric_name1 == "multiple"
      assert is_float(time1)

      assert result2 == :multiple_2
      assert metric_name2 == "multiple"
      assert is_float(time2)
    end

    test "custom metric name can be written on a per-function-header level" do
      result = TimedModule.multiple(:other_argument)
      {metric_name, time, []} = MetricsAgent.get()

      assert result == :multiple_default
      assert metric_name == "multiple_default"
      assert is_float(time)
    end

    test "supports custom metric options" do
      result = TimedModule.custom_metric_options()
      {_metric_name, time, options} = MetricsAgent.get()

      assert result == :custom_metric_options
      assert is_float(time)
      assert options == [tags: [:custom_options_tag]]
    end

    test "custom metric options do not apply to next function in file" do
      result = TimedModule.no_custom_metric_options()
      {_metric_name, time, options} = MetricsAgent.get()

      assert result == :no_custom_metric_options
      assert is_float(time)
      assert options == []
    end

    test "custom metric options apply to multiple function headers" do
      result1 = TimedModule.multiple_options(:option_1)
      {_metric_name, time1, options1} = MetricsAgent.get()

      result2 = TimedModule.multiple_options(:option_2)
      {_metric_name, time2, options2} = MetricsAgent.get()

      assert result1 == :multiple_options_1
      assert is_float(time1)
      assert options1 == [tags: [:multiple_options_tag]]

      assert result2 == :multiple_options_2
      assert is_float(time2)
      assert options2 == [tags: [:multiple_options_tag]]
    end

    test "custom metric options can be written on a per-function-header level" do
      result = TimedModule.multiple_options(:other_argument)
      {_metric_name, time, options} = MetricsAgent.get()

      assert result == :multiple_options_default
      assert is_float(time)
      assert options == [tags: [:multiple_options_default_tag]]
    end
  end
end
