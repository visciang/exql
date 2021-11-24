defmodule Exql.Query do
  @moduledoc false

  @spec result(Postgrex.Result.t()) :: [map()]
  def result(%Postgrex.Result{columns: columns, rows: rows}) do
    Enum.map(rows, fn row ->
      Enum.zip(columns, row) |> Map.new()
    end)
  end
end
