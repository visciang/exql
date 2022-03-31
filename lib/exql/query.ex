defmodule Exql.Query do
  @moduledoc false

  @named_params_re ~r/
    (?:"[^"]+") |
    (?:\'[^\']*\') |
    (?:[^:])(?P<var>:[\w-]+)(?:[^:]?)
  /x

  @spec result_to_map(Postgrex.Result.t()) :: [map()]
  def result_to_map(%Postgrex.Result{columns: nil}), do: []

  def result_to_map(%Postgrex.Result{columns: columns, rows: rows}) do
    Enum.map(rows, fn row ->
      Enum.zip(columns, row) |> Map.new()
    end)
  end

  @type named_param :: atom() | String.t()
  @type named_param_value :: term()
  @type named_param_slice :: {named_param(), {integer(), integer()}}

  @spec named_params(String.t(), %{named_param() => named_param_value()}) ::
          {:error, term()} | {:ok, String.t(), [named_param_value()]}
  def named_params(query_stmt, query_args) do
    query_args = Map.new(query_args, fn {k, v} -> {to_string(k), v} end)
    var_slices = named_params_slices(query_stmt)
    var_names = named_params_var_names(var_slices)
    var_name_to_pos = var_names |> Enum.with_index(1) |> Map.new()
    var_args_bindings = query_args |> Map.keys() |> MapSet.new()

    if MapSet.subset?(var_names, var_args_bindings) do
      positional_query_stmt = positional_query_stmt(query_stmt, var_slices, var_name_to_pos)
      positional_query_args = positional_query_args(query_args, var_name_to_pos)

      {:ok, positional_query_stmt, positional_query_args}
    else
      missing_var_bindings = MapSet.difference(var_names, var_args_bindings) |> Enum.to_list()
      {:error, {:missing_var_bindings, missing_var_bindings}}
    end
  end

  @spec named_params_var_names([named_param_slice()]) :: MapSet.t(named_param())
  defp named_params_var_names(var_slices) do
    MapSet.new(var_slices, fn {var_name, _} -> var_name end)
  end

  @spec positional_query_stmt(String.t(), [named_param_slice()], %{named_param() => integer()}) :: String.t()
  defp positional_query_stmt(query_stmt, var_slices, var_name_to_pos) do
    var_slices
    |> Enum.reduce({0, []}, fn
      {var_name, {offset, len}}, {start_at, acc} ->
        idx = Map.fetch!(var_name_to_pos, var_name)
        next_acc = ["$#{idx}", String.slice(query_stmt, start_at, offset - start_at) | acc]
        next_start_at = offset + len
        {next_start_at, next_acc}
    end)
    |> then(fn {start_at, acc} -> [String.slice(query_stmt, start_at..-1) | acc] end)
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  @spec positional_query_args(%{named_param() => named_param_value()}, %{named_param() => integer()}) :: [
          named_param_value()
        ]
  defp positional_query_args(query_args, var_name_to_pos) do
    var_name_to_pos
    |> Map.to_list()
    |> Enum.sort_by(fn {_var_name, var_idx} -> var_idx end)
    |> Enum.map(fn {var_name, _var_idx} -> Map.fetch!(query_args, var_name) end)
  end

  @spec named_params_slices(String.t()) :: [named_param_slice()]
  defp named_params_slices(query_stmt) do
    @named_params_re
    |> Regex.scan(query_stmt, capture: :all_but_first, return: :index)
    |> List.flatten()
    |> Enum.map(fn {offset, len} = slice ->
      var_name = String.slice(query_stmt, offset + 1, len - 1)
      {var_name, slice}
    end)
  end
end
