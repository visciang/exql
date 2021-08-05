defmodule ExqlMigration.Log do
  @spec last(Postgrex.conn()) :: nil | String.t()
  def last(conn) do
    %Postgrex.Result{rows: [[res]]} = Postgrex.query!(conn, "SELECT max(id) FROM exql_migration.log", [])
    res
  end

  @spec lock(Postgrex.conn()) :: :ok
  def lock(conn) do
    Postgrex.query!(conn, "LOCK TABLE exql_migration.log IN SHARE MODE", [])
    :ok
  end

  @spec insert(Postgrex.conn(), String.t(), String.t(), DateTime.t()) :: Postgrex.Result.t()
  def insert(conn, migration_id, shasum, started_at) do
    Postgrex.query!(
      conn,
      "INSERT INTO exql_migration.log VALUES ($1, $2, $3, clock_timestamp())",
      [migration_id, shasum, started_at]
    )
  end

  @spec clock_timestamp(Postgrex.conn()) :: DateTime.t()
  def clock_timestamp(conn) do
    %Postgrex.Result{rows: [[res]]} = Postgrex.query!(conn, "SELECT clock_timestamp()", [])
    res
  end
end
