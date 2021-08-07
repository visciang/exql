defmodule ExqlMigrationTest do
  use ExUnit.Case

  @postgrex_conn :test

  @postgrex_conf [
    hostname: System.get_env("POSTGRES_HOST", "localhost"),
    username: "postgres",
    password: "postgres",
    database: "postgres",
    name: @postgrex_conn
  ]

  setup_all do
    start_supervised!({Postgrex, @postgrex_conf})
    :ok
  end

  setup do
    on_exit(fn ->
      Postgrex.query!(@postgrex_conn, "DROP SCHEMA IF EXISTS exql_migration CASCADE", [])
      Postgrex.query!(@postgrex_conn, "DROP SCHEMA IF EXISTS test CASCADE", [])
    end)

    :ok
  end

  test "empty list of migration" do
    ExqlMigration.migrate(@postgrex_conn, "test/no_migrations")
    assert ExqlMigration.Log.migrations(@postgrex_conn) == []
  end

  test "basic run" do
    ExqlMigration.migrate(@postgrex_conn, "test/partial_migrations")
    assert [%{id: "001.sql"}] = ExqlMigration.Log.migrations(@postgrex_conn)

    ExqlMigration.migrate(@postgrex_conn, "test/all_migrations")
    assert ExqlMigration.Log.last_migration(@postgrex_conn) == "002.sql"
    assert [%{id: "001.sql"}, %{id: "002.sql"}] = ExqlMigration.Log.migrations(@postgrex_conn)

    ExqlMigration.migrate(@postgrex_conn, "test/partial_migrations")
    assert [%{id: "001.sql"}, %{id: "002.sql"}] = ExqlMigration.Log.migrations(@postgrex_conn)
  end
end
