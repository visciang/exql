defmodule Test.Exql.Migration do
  use ExUnit.Case
  alias Exql.Migration

  @timeout 1_000

  @postgrex_conf [
    hostname: System.get_env("POSTGRES_HOST", "localhost"),
    username: "postgres",
    password: "postgres",
    database: "postgres"
  ]

  setup_all do
    conn = start_supervised!({Postgrex, @postgrex_conf})
    %{conn: conn}
  end

  setup %{conn: conn} do
    on_exit(fn ->
      Postgrex.query!(conn, "drop schema if exists exql_migration cascade", [])
      Postgrex.query!(conn, "drop schema if exists test cascade", [])
    end)

    :ok
  end

  test "empty migrations set", %{conn: conn} do
    Migration.migrate(@postgrex_conf, "test/no_migrations", true, @timeout)
    assert Migration.Log.migrations(conn) == []
  end

  test "add a new migration", %{conn: conn} do
    Migration.migrate(@postgrex_conf, "test/partial_migrations", true, @timeout)
    assert [%{id: "001.sql"}] = Migration.Log.migrations(conn)

    Migration.migrate(@postgrex_conf, "test/all_migrations", true, @timeout)
    assert [%{id: "001.sql"}, %{id: "002.sql"}] = Migration.Log.migrations(conn)
  end

  test "add a new migration (non transactional)", %{conn: conn} do
    Migration.migrate(@postgrex_conf, "test/partial_migrations", false, @timeout)
    assert [%{id: "001.sql"}] = Migration.Log.migrations(conn)

    Migration.migrate(@postgrex_conf, "test/all_migrations", false, @timeout)
    assert [%{id: "001.sql"}, %{id: "002.sql"}] = Migration.Log.migrations(conn)
  end

  test "idempotent", %{conn: conn} do
    Migration.migrate(@postgrex_conf, "test/all_migrations", true, @timeout)
    assert all = [%{id: "001.sql"}, %{id: "002.sql"}] = Migration.Log.migrations(conn)

    Migration.migrate(@postgrex_conf, "test/all_migrations", true, @timeout)
    assert ^all = Migration.Log.migrations(conn)
  end

  test "create DB", %{conn: conn} do
    on_exit(fn ->
      Postgrex.query!(conn, "drop database test_db", [])
    end)

    Migration.create_db(@postgrex_conf, "test_db")
    Migration.create_db(@postgrex_conf, "test_db")

    res = Postgrex.query!(conn, "select true from pg_database where datname = $1", ["test_db"])
    assert %Postgrex.Result{num_rows: 1} = res
  end
end
