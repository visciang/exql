defmodule Test.Exql.Query do
  use ExUnit.Case
  alias Exql.Query

  @postgrex_conn :test

  @postgrex_conf [
    hostname: System.get_env("POSTGRES_HOST", "localhost"),
    username: "postgres",
    password: "postgres",
    database: "postgres",
    name: @postgrex_conn
  ]

  @test_table "query_test_table"

  setup_all do
    start_supervised!({Postgrex, @postgrex_conf})

    Postgrex.query!(@postgrex_conn, "drop table if exists #{@test_table}", [])
    Postgrex.query!(@postgrex_conn, "create table #{@test_table} (x text, y text)", [])

    :ok
  end

  setup do
    on_exit(fn ->
      Postgrex.query!(@postgrex_conn, "truncate table #{@test_table}", [])
    end)
  end

  test "results zip" do
    Postgrex.query!(@postgrex_conn, "insert into #{@test_table} (x, y) values ('a', 'b')", [])

    res = Postgrex.query!(@postgrex_conn, "select * from #{@test_table}", [])
    assert [%{"x" => "a", "y" => "b"}] = Query.result(res)
  end
end
