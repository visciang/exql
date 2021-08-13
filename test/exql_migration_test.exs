defmodule ExqlMigrationTest do
  use ExUnit.Case

  @postgrex_conn :test
  @timeout 1_000

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
      Postgrex.query!(@postgrex_conn, "drop schema if exists exql_migration cascade", [])
      Postgrex.query!(@postgrex_conn, "drop schema if exists test cascade", [])
    end)

    :ok
  end

  test "empty migrations set" do
    ExqlMigration.migrate(@postgrex_conn, "test/no_migrations", @timeout, true)
    assert ExqlMigration.Log.migrations(@postgrex_conn) == []
  end

  test "add a new migration" do
    ExqlMigration.migrate(@postgrex_conn, "test/partial_migrations", @timeout, true)
    assert [%{id: "001.sql"}] = ExqlMigration.Log.migrations(@postgrex_conn)

    ExqlMigration.migrate(@postgrex_conn, "test/all_migrations", @timeout, true)
    assert [%{id: "001.sql"}, %{id: "002.sql"}] = ExqlMigration.Log.migrations(@postgrex_conn)
  end

  test "add a new migration (non transactional)" do
    ExqlMigration.migrate(@postgrex_conn, "test/partial_migrations", @timeout, false)
    assert [%{id: "001.sql"}] = ExqlMigration.Log.migrations(@postgrex_conn)

    ExqlMigration.migrate(@postgrex_conn, "test/all_migrations", @timeout, false)
    assert [%{id: "001.sql"}, %{id: "002.sql"}] = ExqlMigration.Log.migrations(@postgrex_conn)
  end

  test "idempotent" do
    ExqlMigration.migrate(@postgrex_conn, "test/all_migrations", @timeout, true)
    assert all = [%{id: "001.sql"}, %{id: "002.sql"}] = ExqlMigration.Log.migrations(@postgrex_conn)

    ExqlMigration.migrate(@postgrex_conn, "test/all_migrations", @timeout, true)
    assert ^all = ExqlMigration.Log.migrations(@postgrex_conn)
  end

  test "create DB" do
    on_exit(fn ->
      Postgrex.query!(@postgrex_conn, "drop database test_db", [])
    end)

    ExqlMigration.create_db(@postgrex_conn, "test_db")
    ExqlMigration.create_db(@postgrex_conn, "test_db")

    res = Postgrex.query!(@postgrex_conn, "select true from pg_database where datname = $1", ["test_db"])
    assert %Postgrex.Result{num_rows: 1} = res
  end
end
