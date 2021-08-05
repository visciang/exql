defmodule ExqlMigration.Schema do
  @create_schema_stmt """
    CREATE SCHEMA IF NOT EXISTS exql_migration
  """

  @create_log_table_stmt """
    CREATE TABLE IF NOT EXISTS exql_migration.log (
      id         text PRIMARY KEY,
      sha256     text not null,
      exec_start timestamptz not null,
      exec_end   timestamptz not null
    )
  """

  @spec setup(Postgrex.conn()) :: :ok
  def setup(conn) do
    Postgrex.query!(conn, @create_schema_stmt, [])
    Postgrex.query!(conn, @create_log_table_stmt, [])

    :ok
  end
end
