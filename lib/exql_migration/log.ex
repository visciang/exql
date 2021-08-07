defmodule ExqlMigration.Log do
  @moduledoc false

  @type migration_id :: String.t()

  @type record :: %{
    id: migration_id(),
    sha256: String.t(),
    exec_start: DateTime.t(),
    exec_end: DateTime.t()
  }

  @spec migrations(Postgrex.conn()) :: [record()]
  def migrations(conn) do
    %Postgrex.Result{rows: rows} =
      Postgrex.query!(conn, "SELECT id, sha256, exec_start, exec_end FROM exql_migration.log ORDER BY id", [])

      columns = [:id, :sha256, :exec_start, :exec_end]
      Enum.map(rows, fn row -> Map.new(Enum.zip(columns, row)) end)
  end

  @spec last_migration(Postgrex.conn()) :: nil | migration_id()
  def last_migration(conn) do
    %Postgrex.Result{rows: [[res]]} = Postgrex.query!(conn, "SELECT max(id) FROM exql_migration.log", [])
    res
  end

  @spec lock(Postgrex.conn()) :: :ok
  def lock(conn) do
    Postgrex.query!(conn, "LOCK TABLE exql_migration.log IN SHARE MODE", [])
    :ok
  end

  @spec insert(Postgrex.conn(), migration_id(), String.t()) :: Postgrex.Result.t()
  def insert(conn, migration_id, shasum) do
    Postgrex.query!(
      conn,
      "INSERT INTO exql_migration.log VALUES ($1, $2, now(), clock_timestamp())",
      [migration_id, shasum]
    )
  end
end
