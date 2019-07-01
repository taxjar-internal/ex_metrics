defmodule ExMetrics.FunctionTimer do
  @moduledoc """
  The #{__MODULE__} module provides a way to easily time functions and send metrics
  to a StatsD server, with out having to manually time each function.
  """

  defmacro __using__(opts) do
    quote do
      import ExMetrics.FunctionTimer
      @use_histogram Keyword.get(unquote(opts), :use_histogram)
      @default_metric_options []
    end
  end

  defmacro deftimed(head, body \\ nil) do
    {function_name, args_ast} = Macro.decompose_call(head)
    arg_length = length(args_ast)
    function_id = "#{function_name}_#{arg_length}"

    quote do
      @ex_metrics_metric_name metric_name(__MODULE__, unquote(function_id))
      @ex_metrics_metric_options metric_options(__MODULE__, unquote(function_id))
      @timing_function timing_function(__MODULE__)
      def unquote(head) do
        {time, value} = :timer.tc(fn -> unquote(body[:do]) end)
        milliseconds = time / 1_000

        Kernel.apply(ExMetrics, @timing_function, [
          @ex_metrics_metric_name,
          milliseconds,
          @ex_metrics_metric_options
        ])

        value
      end
    end
  end

  @doc ~S"""
  The metric_name/2 function is responsible for fetching the metric
  name for the function being timed. A custom metric name can be set by setting a
  `@metric_name` module attribute above the function, otherwise, a default metric
  name is used.

  If the default metric name is used, it is set as a module attribute, with the
  name `"#{function_id}_metric_name"`.

  If a custom metric name is set with `@metric_name`, the name is moved to the
  `"#{function_id}_metric_name"` module attribute, and `@metric_name` is set to
  `nil` so that it can be overwritten further down in the file.
  """
  def metric_name(module, function_id) do
    if custom_metric_name = Module.get_attribute(module, :metric_name) do
      move_metric_name(module, function_id, custom_metric_name)
    else
      get_metric_name(module, function_id)
    end
  end

  @doc ~S"""
  The metric_options/2 function is responsible for fetching the metric
  options for the function being timed. Custom metric options can be set by setting a
  `@metric_options` module attribute above the function, otherwise, default metric
  options are used.

  If the default metric options are used, they are set as a module attribute, with the
  name `"#{function_id}_metric_options"`.

  If custom metric options are set with `@metric_options`, the options are moved to the
  `"#{function_id}_metric_options"` module attribute, and `@metric_options` is set to
  `nil` so that it can be overwritten further down in the file.
  """
  def metric_options(module, function_id) do
    if custom_metric_options = Module.get_attribute(module, :metric_options) do
      move_metric_options(module, function_id, custom_metric_options)
    else
      get_metric_options(module, function_id)
    end
  end

  @doc ~S"""
  The timing_function/1 function is used to determine whether to
  make a call to ExMetrics.histogram/3 or ExMetrics.timing/3. By default, ExMetrics.timing/3
  will be called, but this can be overriden with:

  defmodule UseHistogram do
    use ExMetrics.FunctionTimer, use_histogram: true
  end
  """
  def timing_function(module) do
    if Module.get_attribute(module, :use_histogram), do: :histogram, else: :timing
  end

  defp move_metric_name(module, function_id, metric_name) do
    metric_name_atom = metric_name_atom(function_id)

    Module.put_attribute(module, metric_name_atom, metric_name)
    Module.put_attribute(module, :metric_name, nil)

    metric_name
  end

  defp get_metric_name(module, function_id) do
    metric_name_atom = metric_name_atom(function_id)

    if function_metric = Module.get_attribute(module, metric_name_atom) do
      function_metric
    else
      default = default_metric_name(module, function_id)
      Module.put_attribute(module, metric_name_atom, default)
      default
    end
  end

  defp metric_name_atom(function_id) do
    String.to_atom("#{function_id}_metric_name")
  end

  defp default_metric_name(module, function_id) do
    String.downcase("function_call.#{module}.#{function_id}")
  end

  defp move_metric_options(module, function_id, options) do
    metric_options_atom = metric_options_atom(function_id)

    Module.put_attribute(module, metric_options_atom, options)
    Module.put_attribute(module, :metric_options, nil)

    options
  end

  defp get_metric_options(module, function_id) do
    metric_options_atom = metric_options_atom(function_id)

    if function_options = Module.get_attribute(module, metric_options_atom) do
      function_options
    else
      defaults = default_metric_options(module)
      Module.put_attribute(module, metric_options_atom, defaults)
      defaults
    end
  end

  defp metric_options_atom(function_id) do
    String.to_atom("#{function_id}_metric_options")
  end

  defp default_metric_options(module) do
    Module.get_attribute(module, :default_metric_options)
  end
end
