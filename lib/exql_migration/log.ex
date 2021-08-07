defmodule ExqlMigration.Log do
  @moduledoc false

  @spec last_migration(Postgrex.conn()) :: nil | String.t()
  def last_migration(conn) do
    %Postgrex.Result{rows: [[res]]} = Postgrex.query!(conn, "SELECT max(id) FROM exql_migration.log", [])
    res
  end

  @spec lock(Postgrex.conn()) :: :ok
  def lock(conn) do
    Postgrex.query!(conn, "LOCK TABLE exql_migration.log IN SHARE MODE", [])
    :ok
  end

  @spec insert(Postgrex.conn(), String.t(), String.t()) :: Postgrex.Result.t()
  def insert(conn, migration_id, shasum) do
    Postgrex.query!(
      conn,
      "INSERT INTO exql_migration.log VALUES ($1, $2, now(), clock_timestamp())",
      [migration_id, shasum]
    )
  end
end
